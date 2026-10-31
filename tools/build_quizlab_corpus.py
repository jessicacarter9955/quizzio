#!/usr/bin/env python3
"""Build Wordweaver's bundled multilingual corpus from the ORIGINAL Quiz Lab
source (preserved under corpus-source/). No online API or hand-import required.
The original files are never overwritten or discarded.
"""
import base64
import hashlib
import json
import pathlib
import re
import unicodedata
import zipfile
from collections import Counter, defaultdict


def normalized(value):
    return re.sub(r"\s+", " ", unicodedata.normalize("NFKC", value).strip().casefold())


def comparable(value, lang):
    """Normalize articles for *comparison only*, never for displayed answers."""
    value = normalized(value)
    articles = {
        "fr": r"^(?:le |la |les |l['’]|un |une |des )",
        "it": r"^(?:il |lo |la |i |gli |le |l['’]|un |uno |una )",
        "es": r"^(?:el |la |los |las |un |una )",
    }
    if lang in articles:
        value = re.sub(articles[lang], "", value)
    return value.strip(" .!?¿¡")


def connect_exact_meanings(terms):
    """Add only missing translations supported by a shared English sense.

    Same spelling alone is insufficient: require another language to agree,
    reject conflicting existing translations, and preserve every original row.
    """
    language_codes = {"en", "it", "es", "fr", "de", "pt", "ru", "ja", "zh", "ko", "ar"}
    by_english = defaultdict(list)
    for row in terms:
        english = row["translations"].get("en", "")
        if english:
            by_english[(row["kind"], normalized(english))].append(row)

    added = Counter()
    for group in by_english.values():
        if len(group) < 2:
            continue
        original = {row["id"]: dict(row["translations"]) for row in group}
        for row in group:
            current = original[row["id"]]
            for lang in (set().union(*(t.keys() for t in original.values()))
                         & language_codes) - current.keys():
                candidates = [(other, t) for other in group
                              if other is not row
                              for t in [original[other["id"]]] if lang in t]
                if not candidates:
                    continue
                variants = {comparable(t[lang], lang) for _, t in candidates}
                if len(variants) != 1:
                    continue
                confirmed = []
                for other, t in candidates:
                    common = (set(current) & set(t)) - {"en"}
                    if (common and all(comparable(current[k], k) == comparable(t[k], k)
                                       for k in common)):
                        confirmed.append((len(common), other, t))
                if not confirmed:
                    continue
                _, witness, witness_values = max(confirmed, key=lambda item: item[0])
                row["translations"][lang] = witness_values[lang]
                row.setdefault("inferredFrom", {})[lang] = witness["id"]
                added[lang] += 1
    return added


def conversation_terms(root):
    """Align the small Quiz Lab question JSONs on the *same English prompt*."""
    grouped = {}
    for lang in ("ar", "es", "fr", "it", "pt", "ru"):
        # The older Italian JSON has malformed control characters; v2 is valid.
        filename = "quiz_en_it_v2.json" if lang == "it" else f"quiz_en_{lang}.json"
        data = json.loads((root / "assets" / "data" / filename).read_text(encoding="utf-8"))
        for question in data.get("questions", []):
            en = str(question.get("sourceEnglish") or "").strip()
            translation = str(question.get("correctAnswer") or "").strip()
            if not en or not translation:
                continue
            key = normalized(en)
            row = grouped.setdefault(key, {
                "id": "conversation:" + hashlib.sha256(key.encode()).hexdigest()[:20],
                "category": "Conversation", "subtopic": "Phrases", "kind": "phrase",
                "translations": {"en": en},
            })
            previous = row["translations"].get(lang)
            if previous is not None and normalized(previous) != normalized(translation):
                raise ValueError(f"Conflicting {lang} translations for {en}")
            row["translations"][lang] = translation
    return list(grouped.values())

ROOT = pathlib.Path(__file__).resolve().parent.parent
parts = sorted((ROOT / "corpus-source").glob("part*.b64"))
if len(parts) != 5:
    raise SystemExit("Expected all five original Quiz Lab archive parts")
data = base64.b64decode("".join(p.read_text(encoding="utf-8") for p in parts))
archive_path = ROOT / ".quizlab-original-tmp.zip"
archive_path.write_bytes(data)
sources = [
    "user_language_quizlab.json",
    "starter_languages.json",
    "quizlab_original_100_topics.json",
    "quizlab_400_continuation.json",
    "user_language_reference.json",
]
unique = {}
counts = Counter()
with zipfile.ZipFile(archive_path) as archive:
    for name in sources:
        path = "Quiz-Lab-Flutter/assets/data/" + name
        document = json.loads(archive.read(path).decode("utf-8"))
        rows = document.get("terms", document.get("entries", []))
        counts[name] = len(rows)
        for row in rows:
            if not isinstance(row, dict):
                continue
            translations = row.get("translations") or row.get("words") or {}
            if not isinstance(translations, dict):
                continue
            translations = {
                str(lang).lower(): str(value).strip()
                for lang, value in translations.items()
                if isinstance(value, str) and value.strip()
            }
            if len(translations) < 2:
                continue
            category = str(row.get("category") or row.get("topic") or "General")
            subtopic = str(row.get("subtopic") or "General")
            kind = str(row.get("kind") or row.get("type") or "word")
            # Preserve both homographs and legitimate cross-topic occurrences;
            # collapse only identical translations within the same taxonomy node.
            key = json.dumps([kind, category.strip().casefold(), subtopic.strip().casefold(),
                              sorted(translations.items())],
                             ensure_ascii=False, separators=(",", ":"))
            if key in unique:
                continue
            term_id = hashlib.sha256(key.encode("utf-8")).hexdigest()[:20]
            unique[key] = {
                "id": "quizlab:" + term_id,
                "category": category,
                "subtopic": subtopic,
                "kind": kind,
                "translations": translations,
            }

archive_path.unlink(missing_ok=True)
terms = list(unique.values())
if len(terms) < 500:
    raise SystemExit(f"Too few original Quiz Lab terms: {len(terms)}")
conversation = conversation_terms(ROOT)
terms.extend(conversation)
inferred = connect_exact_meanings(terms)
out = ROOT / "assets" / "data" / "quizlab_terms.json"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps({"version": 2, "source": "Quiz Lab original + linked conversation JSONs",
                           "terms": terms}, ensure_ascii=False,
                          separators=(",", ":")), encoding="utf-8")
print("QUIZLAB ORIGINAL SOURCE COUNTS:", dict(counts))
print("QUIZLAB CONVERSATION PHRASES:", len(conversation))
print("QUIZLAB VERIFIED INFERENCES:", dict(inferred))
print("QUIZLAB UNIQUE MULTILINGUAL TERMS:", len(terms))
print("QUIZLAB TERMS PER LANGUAGE:", dict(Counter(
    lang for term in terms for lang in term["translations"])))
print("QUIZLAB CORPUS OUTPUT:", str(out), out.stat().st_size, "bytes")

