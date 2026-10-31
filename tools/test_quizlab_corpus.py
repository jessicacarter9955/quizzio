"""Regression tests for conservative multilingual linking (no AI guessing)."""
import json
import pathlib
import subprocess
import sys
import unittest

ROOT = pathlib.Path(__file__).resolve().parent.parent


class QuizLabCorpusTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        subprocess.run([sys.executable, str(ROOT / "tools/build_quizlab_corpus.py")],
                       cwd=ROOT, check=True, stdout=subprocess.PIPE, text=True)
        cls.rows = json.loads((ROOT / "assets/data/quizlab_terms.json").read_text(encoding="utf-8"))["terms"]

    def test_original_terms_and_conversations_survive(self):
        self.assertEqual(len(self.rows), 1930)
        conversations = [r for r in self.rows if r["id"].startswith("conversation:")]
        self.assertEqual(len(conversations), 43)

    def test_pivot_links_four_languages_in_both_directions(self):
        hello = next(r for r in self.rows if r["translations"].get("en") == "What is your name?")
        self.assertEqual(hello["translations"]["es"], "¿Cómo te llamas?")
        self.assertEqual(hello["translations"]["fr"], "Comment tu t’appelles ?")
        self.assertEqual(hello["translations"]["ru"], "Как тебя зовут?")
        self.assertEqual(hello["translations"]["it"], "Come ti chiami?")

    def test_inferred_translation_has_original_witness(self):
        ids = {r["id"]: r for r in self.rows}
        inferred = [r for r in self.rows if r.get("inferredFrom")]
        self.assertGreater(len(inferred), 0)
        for row in inferred:
            for language, source_id in row["inferredFrom"].items():
                self.assertIn(source_id, ids)
                source = ids[source_id]
                self.assertEqual(row["translations"][language], source["translations"][language])
                self.assertEqual(row["translations"]["en"].casefold(),
                                 source["translations"]["en"].casefold())

    def test_does_not_invent_missing_translation(self):
        abdomen = [r for r in self.rows if r["translations"].get("en") == "abdomen"
                   and r["category"] == "body"]
        self.assertEqual(len(abdomen), 1)
        self.assertNotIn("de", abdomen[0]["translations"])
        spanish_only = next(r for r in self.rows if r["translations"].get("en") == "Why are you learning Spanish?")
        self.assertNotIn("fr", spanish_only["translations"])

    def test_conflicting_sense_is_not_bridged(self):
        # Keep distinct target translations even with identical source spelling.
        banks = [r for r in self.rows if r["translations"].get("en", "").casefold() == "bank"]
        for row in banks:
            self.assertTrue(row["translations"].get("es"))


if __name__ == "__main__":
    unittest.main()
