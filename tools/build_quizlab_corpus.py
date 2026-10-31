#!/usr/bin/env python3
"""Build Wordweaver's bundled multilingual corpus from the ORIGINAL Quiz Lab
source (preserved under corpus-source/). No online API or hand-import required.
The original files are never overwritten or discarded.
"""
import base64
import hashlib
import json
import pathlib
import zipfile
from collections import Counter

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
            key = json.dumps([kind, category.strip().casefold(), subtopic.strip().casefold(),\n                              sorted(translations.items())],
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
out = ROOT / "assets" / "data" / "quizlab_terms.json"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps({"version": 1, "source": "Quiz Lab original",
                           "terms": terms}, ensure_ascii=False,
                          separators=(",", ":")), encoding="utf-8")
print("QUIZLAB ORIGINAL SOURCE COUNTS:", dict(counts))
print("QUIZLAB UNIQUE MULTILINGUAL TERMS:", len(terms))
print("QUIZLAB TERMS PER LANGUAGE:", dict(Counter(
    lang for term in terms for lang in term["translations"])))
print("QUIZLAB CORPUS OUTPUT:", str(out), out.stat().st_size, "bytes")
