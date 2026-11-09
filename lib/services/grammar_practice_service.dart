import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordweaver/models/vocabulary_word.dart';

/// Generates only grammatical noun phrases. Unsupported nouns/languages are
/// skipped by grammar quizzes rather than receiving a guessed gender or article.
class GrammarPracticeService extends ChangeNotifier {
  GrammarPracticeService._() { ready = _load(); }
  static final GrammarPracticeService _instance = GrammarPracticeService._();
  factory GrammarPracticeService() => _instance;

  static const _articleKey = 'wordweaver.grammar.articles.v1';
  static const _possessiveKey = 'wordweaver.grammar.possessive.v1';
  static const _indefiniteKey = 'wordweaver.grammar.indefinite.v1';

  late final Future<void> ready;
  bool articles = false;
  bool possessives = false;
  bool indefinite = false;
  bool get active => articles || possessives;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    articles = prefs.getBool(_articleKey) ?? false;
    possessives = prefs.getBool(_possessiveKey) ?? false;
    indefinite = prefs.getBool(_indefiniteKey) ?? false;
    notifyListeners();
  }

  Future<void> setArticles(bool value) async {
    await ready;
    articles = value;
    notifyListeners();
    (await SharedPreferences.getInstance()).setBool(_articleKey, value);
  }

  Future<void> setPossessives(bool value) async {
    await ready;
    possessives = value;
    notifyListeners();
    (await SharedPreferences.getInstance()).setBool(_possessiveKey, value);
  }

  Future<void> setIndefinite(bool value) async {
    await ready;
    indefinite = value;
    notifyListeners();
    (await SharedPreferences.getInstance()).setBool(_indefiniteKey, value);
  }

  // Constrain to noun-focused topics; a verb ending in -a/-o is not a noun.
  static const nounTopics = <String>{
    'food', 'body', 'home_and_rooms', 'fauna', 'flora', 'transportation',
    'shopping_mall', 'school', 'family_and_relationships',
  };

  // Explicit genders for nouns where suffixes do not establish gender.
  // Add verified lemma metadata here as the vocabulary expands.
  static const Map<String, Map<String, String>> genders = {
    'it': {
      'hamburger': 'm', 'panino': 'm', 'pane': 'm', 'formaggio': 'm',
      'latte': 'm', 'riso': 'm', 'pollo': 'm', 'pesce': 'm', 'gelato': 'm',
      'caffè': 'm', 'tè': 'm', 'succo': 'm', 'burro': 'm', 'uovo': 'm',
      'olio': 'm', 'limone': 'm', 'pomodoro': 'm', 'cioccolato': 'm',
      'yogurt': 'm', 'computer': 'm', 'libro': 'm', 'tavolo': 'm',
      'cane': 'm', 'gatto': 'm', 'telefono': 'm', 'treno': 'm',
      'fiore': 'm', 'albero': 'm', 'zaino': 'm', 'studente': 'm',
      'amico': 'm', 'pizza': 'f', 'pasta': 'f', 'mela': 'f',
      'banana': 'f', 'arancia': 'f', 'acqua': 'f', 'birra': 'f',
      'carne': 'f', 'insalata': 'f', 'zuppa': 'f', 'fragola': 'f',
      'patata': 'f', 'cipolla': 'f', 'pera': 'f', 'torta': 'f',
      'casa': 'f', 'macchina': 'f', 'sedia': 'f', 'porta': 'f',
      'finestra': 'f', 'strada': 'f', 'stanza': 'f', 'scuola': 'f',
      'famiglia': 'f',
    },
    'es': {
      'hamburguesa': 'f', 'hamburger': 'm', 'pan': 'm',
      'queso': 'm', 'leche': 'f', 'agua': 'f', 'arroz': 'm',
      'carne': 'f', 'pescado': 'm', 'pollo': 'm', 'café': 'm',
      'té': 'm', 'zumo': 'm', 'jugo': 'm', 'huevo': 'm',
      'aceite': 'm', 'chocolate': 'm', 'yogur': 'm',
      'manzana': 'f', 'naranja': 'f', 'pizza': 'f',
      'pasta': 'f', 'ensalada': 'f', 'sopa': 'f',
      'hamburguesas': 'f', 'libro': 'm', 'coche': 'm',
      'ordenador': 'm', 'teléfono': 'm', 'perro': 'm',
      'gato': 'm', 'ciudad': 'f', 'calle': 'f', 'flor': 'f',
      'árbol': 'm', 'mano': 'f', 'día': 'm',
    },
    'pt': {
      'hambúrguer': 'm', 'hamburger': 'm', 'pão': 'm',
      'queijo': 'm', 'leite': 'm', 'água': 'f',
      'arroz': 'm', 'carne': 'f', 'peixe': 'm',
      'frango': 'm', 'café': 'm', 'chá': 'm',
      'ovo': 'm', 'chocolate': 'm', 'sorvete': 'm',
      'maçã': 'f', 'pizza': 'f', 'salada': 'f',
      'sopa': 'f', 'banana': 'f', 'laranja': 'f',
      'casa': 'f', 'livro': 'm', 'carro': 'm',
      'cidade': 'f', 'leão': 'm', 'flor': 'f',
    },
    'fr': {
      'hamburger': 'm', 'burger': 'm', 'pain': 'm',
      'fromage': 'm', 'lait': 'm', 'riz': 'm',
      'poisson': 'm', 'poulet': 'm', 'café': 'm',
      'thé': 'm', 'jus': 'm', 'beurre': 'm',
      'œuf': 'm', 'oeuf': 'm', 'chocolat': 'm',
      'yaourt': 'm', 'livre': 'm', 'chien': 'm',
      'chat': 'm', 'téléphone': 'm', 'ordinateur': 'm',
      'travail': 'm', 'arbre': 'm', 'pomme': 'f',
      'pizza': 'f', 'banane': 'f', 'orange': 'f',
      'eau': 'f', 'viande': 'f', 'salade': 'f',
      'soupe': 'f', 'glace': 'f', 'maison': 'f',
      'voiture': 'f', 'table': 'f', 'chaise': 'f',
      'ville': 'f', 'chambre': 'f', 'porte': 'f',
      'fenêtre': 'f', 'rue': 'f', 'école': 'f',
      'famille': 'f', 'fleur': 'f',
    },
    'de': {
      'hamburger': 'm', 'burger': 'm', 'käse': 'm',
      'kaffee': 'm', 'tee': 'm', 'reis': 'm',
      'fisch': 'm', 'apfel': 'm', 'saft': 'm',
      'tisch': 'm', 'hund': 'm', 'computer': 'm',
      'zug': 'm', 'pizza': 'f', 'banane': 'f',
      'orange': 'f', 'milch': 'f', 'butter': 'f',
      'wurst': 'f', 'suppe': 'f', 'kartoffel': 'f',
      'birne': 'f', 'schokolade': 'f', 'schule': 'f',
      'straße': 'f', 'katze': 'f', 'tür': 'f',
      'stadt': 'f', 'blume': 'f', 'brot': 'n',
      'wasser': 'n', 'fleisch': 'n', 'ei': 'n',
      'huhn': 'n', 'bier': 'n', 'eis': 'n',
      'haus': 'n', 'buch': 'n', 'fenster': 'n',
      'auto': 'n', 'zimmer': 'n', 'telefon': 'n',
      'kind': 'n',
    },
  };

  static const _uncountableEnglish = <String>{
    'water', 'milk', 'bread', 'rice', 'cheese', 'butter', 'meat',
    'flour', 'salt', 'sugar', 'air', 'information',
  };

  // Returns (bare lemma, grammatical gender), or null if unreliable.
  (String, String)? _noun(String lang, String raw) {
    var lemma = raw.trim().replaceAll('’', "'");
    if (lemma.isEmpty || RegExp(r'[!?¿¡.;:\n]').hasMatch(lemma)) return null;
    String? gender;
    final tokens = <String, String>{
      'it': r"^(il |lo |la |l'|un |uno |una |un')",
      'es': r'^(el |la |un |una )',
      'fr': r"^(le |la |l'|un |une )",
      'pt': r'^(o |a |um |uma )',
      'en': r'^(the |an |a )',
      'de': r'^(der |die |das |ein |eine )',
    };
    final expression = tokens[lang];
    if (expression == null) return null;
    final match = RegExp(expression, caseSensitive: false).firstMatch(lemma);
    if (match != null) {
      final article = match.group(0)!.trim().toLowerCase();
      if (lang == 'it') {
        if (['il', 'lo', 'un', 'uno'].contains(article)) gender = 'm';
        if (['la', 'una', "un'"].contains(article)) gender = 'f';
      } else if (lang == 'es') {
        if (['el', 'un'].contains(article)) gender = 'm';
        if (['la', 'una'].contains(article)) gender = 'f';
      } else if (lang == 'fr') {
        if (['le', 'un'].contains(article)) gender = 'm';
        if (['la', 'une'].contains(article)) gender = 'f';
      } else if (lang == 'pt') {
        if (['o', 'um'].contains(article)) gender = 'm';
        if (['a', 'uma'].contains(article)) gender = 'f';
      } else if (lang == 'de') {
        gender = {'der':'m', 'die':'f', 'das':'n',
          'ein':'m', 'eine':'f'}[article];
      }
      lemma = lemma.substring(match.end).trim();
    }
    if (lemma.isEmpty) return null;
    final lowercase = lemma.toLowerCase();
    // Never guess the part of speech of an arbitrary multiword sentence.
    if (lemma.contains(' ') && !(genders[lang]?.containsKey(lowercase) ?? false)) {
      return null;
    }
    if (lang == 'en') {
      if (RegExp(r'[^a-zA-Z -]').hasMatch(lemma)) return null;
      // English plural forms and verbal phrases require separate metadata.
      if (lowercase.endsWith('s') && !lowercase.endsWith('ss')) return null;
      return (lemma, 'n');
    }
    gender = genders[lang]?[lowercase] ?? gender;
    // High-confidence singular noun suffixes only in the Romance languages.
    if (gender == null && ['it', 'es', 'pt'].contains(lang)) {
      if (lowercase.endsWith('o')) gender = 'm';
      if (lowercase.endsWith('a')) gender = 'f';
    }
    if (gender == null) return null;
    return (lemma, gender);
  }

  String? format(String lang, String raw) {
    if (!active) return raw;
    final noun = _noun(lang, raw);
    if (noun == null) return null;
    final (base, gender) = noun;
    final lower = base.toLowerCase();
    final vowelInitial = RegExp(r'^[aeiouàèéìòùáíóúâêîôûäëïöüœ]', caseSensitive: false)
        .hasMatch(base);
    // French aspirated h (e.g. hamburger) never elides; Italian h does.
    final vowel = vowelInitial || (lang == 'it' && lower.startsWith('h')) ||
        (lang == 'fr' && {'homme', 'hôtel', 'heure', 'histoire'}.contains(lower)) ||
        (lang == 'en' && {'hour', 'honest man', 'honor', 'heir'}.contains(lower));
    final articleType = indefinite && !possessives;
    if (lang == 'en') {
      if (possessives) return 'my $base';
      if (!articleType) return 'the $base';
      if (_uncountableEnglish.contains(lower)) return null;
      final an = vowel && !RegExp(r'^(uni[^n]|use|one)', caseSensitive: false).hasMatch(base);
      return '${an ? 'an' : 'a'} $base';
    }
    if (lang == 'it') {
      if (possessives) return '${gender == 'f' ? 'la mia' : 'il mio'} $base';
      final special = RegExp(r'^(s[^aeiouàèéìòù]|z|ps|pn|gn|x|y)', caseSensitive: false).hasMatch(base);
      if (articleType) {
        if (gender == 'f') return '${vowel ? "un'" : 'una '}$base';
        return '${special ? 'uno' : 'un'} $base';
      }
      if (vowel) return "l'$base";
      return '${gender == 'f' ? 'la' : (special ? 'lo' : 'il')} $base';
    }
    if (lang == 'es') {
      if (possessives) return 'mi $base';
      // Stressed initial a takes el/un despite feminine agreement.
      final stressedA = gender == 'f' && {'agua', 'águila', 'hacha', 'hambre'}.contains(lower);
      final masculineArticle = gender == 'm' || stressedA;
      return '${articleType ? (masculineArticle ? 'un' : 'una') : (masculineArticle ? 'el' : 'la')} $base';
    }
    if (lang == 'fr') {
      if (possessives) return '${gender == 'm' || vowel ? 'mon' : 'ma'} $base';
      if (articleType) return '${gender == 'm' ? 'un' : 'une'} $base';
      return vowel ? "l'$base" : '${gender == 'm' ? 'le' : 'la'} $base';
    }
    if (lang == 'pt') {
      if (possessives) return '${gender == 'm' ? 'o meu' : 'a minha'} $base';
      return '${articleType ? (gender == 'm' ? 'um' : 'uma') : (gender == 'm' ? 'o' : 'a')} $base';
    }
    if (lang == 'de') {
      final noun = '${base[0].toUpperCase()}${base.substring(1)}';
      if (possessives) return '${gender == 'f' ? 'meine' : 'mein'} $noun';
      const definite = {'m':'der', 'f':'die', 'n':'das'};
      return '${articleType ? (gender == 'f' ? 'eine' : 'ein') : definite[gender]} $noun';
    }
    return null;
  }

  bool _hasNounEvidence(String lang, String raw) {
    final value = raw.trim().replaceAll('’', "'").toLowerCase();
    if (genders[lang]?.containsKey(value) ?? false) return true;
    const articles = <String, String>{
      'it': r"^(il |lo |la |l'|un |uno |una |un')",
      'es': r'^(el |la |un |una )',
      'fr': r"^(le |la |l'|un |une )",
      'pt': r'^(o |a |um |uma )',
      'de': r'^(der |die |das |ein |eine )',
      'en': r'^(the |an |a )',
    };
    final prefix = articles[lang];
    return prefix != null && RegExp(prefix).hasMatch(value);
  }

  bool isEligible(VocabularyWord word) {
    if (!active) return true;
    if (!nounTopics.contains(word.topic)) return false;
    final langs = word.languagePairKey.split('_');
    if (langs.length != 2) return false;
    if (format(langs[0], word.sourceWord) == null ||
        format(langs[1], word.targetWord) == null) return false;
    // A gender-looking suffix does not prove a word is a noun: "mangio"
    // and "como" are verbs. Require an attested noun on at least one side.
    return _hasNounEvidence(langs[0], word.sourceWord) ||
        _hasNounEvidence(langs[1], word.targetWord);
  }

  String display(VocabularyWord word, {required bool source}) {
    if (!isEligible(word)) return source ? word.sourceWord : word.targetWord;
    final code = word.languagePairKey.split('_')[source ? 0 : 1];
    return format(code, source ? word.sourceWord : word.targetWord)!;
  }
}
