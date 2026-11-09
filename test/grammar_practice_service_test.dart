import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordweaver/models/vocabulary_word.dart';
import 'package:wordweaver/services/grammar_practice_service.dart';

VocabularyWord noun(String pair, String source, String target, {String topic = 'food'}) =>
    VocabularyWord(
      id: 'test', sourceWord: source, targetWord: target,
      languagePairKey: pair, topic: topic, createdAt: DateTime.utc(2026),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GrammarPracticeService grammar;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    grammar = GrammarPracticeService();
    await grammar.ready;
  });

  setUp(() async {
    await grammar.setArticles(false);
    await grammar.setPossessives(false);
    await grammar.setIndefinite(false);
  });

  test('switches work separately and together in both language directions', () async {
    final w = noun('it_en', 'hamburger', 'hamburger');
    await grammar.setArticles(true);
    expect(grammar.display(w, source: true), 'l\'hamburger');
    expect(grammar.display(w, source: false), 'the hamburger');

    await grammar.setPossessives(true);
    expect(grammar.display(w, source: true), 'il mio hamburger');
    expect(grammar.display(w, source: false), 'my hamburger');

    await grammar.setArticles(false);
    expect(grammar.display(w, source: true), 'il mio hamburger');
    expect(grammar.display(w, source: false), 'my hamburger');

    final reverse = noun('en_it', 'hamburger', 'hamburger');
    expect(grammar.display(reverse, source: true), 'my hamburger');
    expect(grammar.display(reverse, source: false), 'il mio hamburger');
  });

  test('definite/indefinite inflections for Italian and Spanish', () async {
    await grammar.setArticles(true);
    await grammar.setIndefinite(true);
    final pizza = noun('en_it', 'pizza', 'pizza');
    expect(grammar.display(pizza, source: true), 'a pizza');
    expect(grammar.display(pizza, source: false), 'una pizza');
    final student = noun('en_it', 'student', 'studente', topic: 'school');
    expect(grammar.display(student, source: false), 'uno studente');
    final water = noun('en_es', 'water', 'agua');
    expect(grammar.isEligible(water), isFalse); // mass noun: no "a water"
    final burger = noun('en_es', 'hamburger', 'hamburguesa');
    expect(grammar.display(burger, source: false), 'una hamburguesa');
    await grammar.setIndefinite(false);
    expect(grammar.display(burger, source: false), 'la hamburguesa');
    expect(grammar.format('es', 'agua'), 'el agua');
  });

  test('French elision, possessive vowel agreement and German gender', () async {
    await grammar.setArticles(true);
    final apple = noun('en_fr', 'apple', 'pomme');
    expect(grammar.display(apple, source: false), 'la pomme');
    expect(grammar.format('fr', 'eau'), "l'eau");
    final book = noun('en_de', 'book', 'Buch');
    expect(grammar.display(book, source: false), 'das Buch');
    await grammar.setPossessives(true);
    expect(grammar.format('fr', 'eau'), 'mon eau');
    expect(grammar.display(apple, source: false), 'ma pomme');
    expect(grammar.display(book, source: false), 'mein Buch');
  });

  test('skips unsupported languages, non-nouns and ambiguous gender', () async {
    await grammar.setArticles(true);
    expect(grammar.isEligible(noun('en_ru', 'hamburger', 'гамбургер')), isFalse);
    expect(grammar.isEligible(noun('en_it', 'eat', 'mangiare')), isFalse);
    expect(grammar.isEligible(noun('en_it', 'eat', 'mangio')), isFalse);
    expect(grammar.isEligible(noun('it_es', 'mangio', 'como')), isFalse);
    expect(grammar.isEligible(noun('en_fr', 'zebra', 'zèbre')), isFalse);
    expect(grammar.isEligible(noun('en_it', 'go', 'vado', topic: 'conversation')), isFalse);
  });

  test('switch settings are persisted', () async {
    await grammar.setArticles(true);
    await grammar.setPossessives(true);
    await grammar.setIndefinite(true);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('wordweaver.grammar.articles.v1'), true);
    expect(prefs.getBool('wordweaver.grammar.possessive.v1'), true);
    expect(prefs.getBool('wordweaver.grammar.indefinite.v1'), true);
    expect(grammar.format('it', 'hamburger'), 'il mio hamburger');
  });
}
