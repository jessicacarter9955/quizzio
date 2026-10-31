import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wordweaver/models/language.dart';
import 'package:wordweaver/models/language_pair.dart';
import 'package:wordweaver/models/quiz_question.dart';
import 'package:wordweaver/models/topic.dart';
import 'package:wordweaver/models/vocabulary_word.dart';
import 'package:wordweaver/screens/pattern_mnemonic_page.dart';
import 'package:wordweaver/screens/pattern_screen.dart';
import 'package:wordweaver/screens/pattern_writing_page.dart';
import 'package:wordweaver/screens/quiz_page.dart';
import 'package:wordweaver/services/language_service.dart';
import 'package:wordweaver/services/topic_service.dart';
import 'package:wordweaver/services/vocabulary_service.dart';
import 'package:wordweaver/services/word_mistake_service.dart';

/// Review real mistakes, sorted and filtered without creating fake translations.
class MistakeReviewPage extends StatefulWidget {
  const MistakeReviewPage({super.key});

  @override
  State<MistakeReviewPage> createState() => _MistakeReviewPageState();
}

class _MistakeReviewPageState extends State<MistakeReviewPage> {
  final _mistakes = WordMistakeService();
  final _topics = TopicService();
  final _vocabulary = VocabularyService();
  final _search = TextEditingController();
  final Set<String> _selectedKeys = {};
  late final Future<void> _ready;
  String? _pairFilter;
  String? _topicFilter;
  String _originFilter = 'all';
  String _sort = 'count';
  String _practiceMode = 'standard';

  @override
  void initState() {
    super.initState();
    _ready = Future.wait([_mistakes.ready, _topics.ready, _vocabulary.ready]);
    _search.addListener(_onSearch);
  }

  void _onSearch() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _search.removeListener(_onSearch);
    _search.dispose();
    super.dispose();
  }

  String _topicName(String id) {
    for (final topic in _topics.topics) {
      if (topic.id == id) return '${topic.emoji} ${topic.name}';
    }
    return id == 'uncategorized' ? 'Uncategorized' : id;
  }

  String _categorySortKey(String id) {
    for (final topic in _topics.topics) {
      if (topic.id == id) return topic.name.toLowerCase();
    }
    return id.toLowerCase();
  }

  String _pairName(String id) => id.split('_').join(' → ').toUpperCase();

  int _wrongInFilter(WordMistakeRecord row) => _originFilter == 'all'
      ? row.wrong : (row.wrongByMode[_originFilter] ?? 0);

  List<WordMistakeRecord> _visible(String pair) {
    final term = _search.text.trim().toLowerCase();
    final rows = _mistakes.mistakes.where((row) {
      if (row.pairKey != pair || _wrongInFilter(row) == 0) return false;
      if (_topicFilter != null && !row.topics.contains(_topicFilter)) return false;
      return term.isEmpty || row.source.toLowerCase().contains(term) ||
          row.target.toLowerCase().contains(term);
    }).toList();
    rows.sort((a, b) {
      int comparison;
      switch (_sort) {
        case 'rate':
          comparison = b.errorRate.compareTo(a.errorRate);
          break;
        case 'recent':
          comparison = (b.lastWrong ?? b.lastAttempt)
              .compareTo(a.lastWrong ?? a.lastAttempt);
          break;
        case 'category':
          comparison = _categorySortKey(a.topic)
              .compareTo(_categorySortKey(b.topic));
          break;
        case 'az':
          comparison = a.source.toLowerCase().compareTo(b.source.toLowerCase());
          break;
        default:
          comparison = _wrongInFilter(b).compareTo(_wrongInFilter(a));
      }
      return comparison != 0 ? comparison : b.wrong.compareTo(a.wrong);
    });
    return rows;
  }

  LanguagePair _languagePair(String pairKey) {
    final parts = pairKey.split('_');
    Language byCode(String code) => Language.supported.firstWhere(
        (language) => language.code == code,
        orElse: () => Language.supported.first);
    return LanguagePair(source: byCode(parts[0]), target: byCode(parts[1]));
  }

  List<QuizQuestion> _questions(List<VocabularyWord> words, String pair) {
    final random = Random();
    final results = <QuizQuestion>[];
    for (final word in words) {
      final candidates = <String>{
        ...words.map((item) => item.targetWord)
            .where((value) => value != word.targetWord),
        ..._vocabulary.getRandomWrongAnswers(pair, word.targetWord, 16),
      }.toList()..shuffle(random);
      final wrong = candidates.take(3).toList();
      if (wrong.isEmpty) continue;
      final options = [word.targetWord, ...wrong]..shuffle(random);
      results.add(QuizQuestion(
        word: word,
        options: options,
        correctIndex: options.indexOf(word.targetWord),
        wrongAnswers: wrong,
        topic: word.topic,
      ));
    }
    return results..shuffle(random);
  }

  void _startReview(String pair, List<WordMistakeRecord> visible) {
    final chosen = visible.where((row) => _selectedKeys.contains(row.key)).toList();
    final pool = chosen.isEmpty ? visible : chosen;
    if (pool.isEmpty) return;
    final words = pool.map((row) => row.toVocabularyWord()).toList();
    final languagePair = _languagePair(pair);
    final ids = words.map((word) => word.topic).toSet();
    final selectedTopics = <Topic>[
      for (final id in ids)
        _topics.topics.where((t) => t.id == id).firstOrNull ??
            Topic(id: id, name: _topicName(id), emoji: '📚'),
    ];
    Widget page;
    switch (_practiceMode) {
      case 'writing':
        page = PatternWritingPage(words: words, pairKey: pair);
        break;
      case 'mnemonic':
        page = PatternMnemonicPage(
          words: words, pairKey: pair, forcePractice: true);
        break;
      case 'patterns':
        page = PatternScreen(reviewWords: words, reviewPair: languagePair);
        break;
      default:
        final questions = _questions(words, pair);
        if (questions.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Not enough translations for answer choices.'),
          ));
          return;
        }
        page = QuizPage(
          languagePair: languagePair,
          selectedTopics: selectedTopics,
          questionCount: questions.length,
          answerOptionCount: 3,
          initialQuestions: questions,
          speakingMode: _practiceMode == 'speaking',
        );
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> options,
    required ValueChanged<String?> onChanged,
    double width = 180,
  }) => SizedBox(
        width: width,
        child: DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
          ),
          items: options,
          onChanged: onChanged,
        ),
      );

  DropdownMenuItem<String> _option(String value, String text) =>
      DropdownMenuItem(value: value, child: Text(text, overflow: TextOverflow.ellipsis));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Most missed words')),
      body: FutureBuilder<void>(
        future: _ready,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListenableBuilder(
            listenable: _mistakes,
            builder: (context, _) {
              final all = _mistakes.mistakes;
              if (all.isEmpty) {
                return Center(child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_circle_outline, size: 54,
                        color: theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text('No missed words yet', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text('Incorrect answers from quizzes, Writing and Mnemonic '
                        'will appear here. Existing Writing history is imported once.',
                        textAlign: TextAlign.center),
                  ]),
                ));
              }
              final pairs = all.map((row) => row.pairKey).toSet().toList()..sort();
              final preferred = LanguageService().currentLanguagePairKey;
              final pair = _pairFilter != null && pairs.contains(_pairFilter)
                  ? _pairFilter!
                  : (pairs.contains(preferred) ? preferred : pairs.first);
              final categories = all.where((row) => row.pairKey == pair)
                  .expand((row) => row.topics).toSet().toList()
                ..sort((a, b) => _categorySortKey(a).compareTo(_categorySortKey(b)));
              final visible = _visible(pair);
              final selectedCount = visible.where((row) => _selectedKeys.contains(row.key)).length;
              final reviewCount = selectedCount == 0 ? visible.length : selectedCount;

              return Column(children: [
                Expanded(child: CustomScrollView(slivers: [
                  SliverToBoxAdapter(child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${_mistakes.mistakenWordCount} difficult words · '
                          '${_mistakes.totalMistakes} incorrect answers',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _search,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search source or translation',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(spacing: 10, runSpacing: 10, children: [
                        _dropdown(label: 'Language pair', value: pair, width: 170,
                          options: [for (final id in pairs) _option(id, _pairName(id))],
                          onChanged: (v) => setState(() {
                            _pairFilter = v; _topicFilter = null; _selectedKeys.clear();
                          })),
                        _dropdown(label: 'Category',
                          value: categories.contains(_topicFilter) ? _topicFilter! : 'all',
                          width: 180,
                          options: [_option('all', 'All categories'),
                            for (final id in categories) _option(id, _topicName(id))],
                          onChanged: (v) => setState(() {
                            _topicFilter = v == 'all' ? null : v;
                            _selectedKeys.clear();
                          })),
                        _dropdown(label: 'Error origin', value: _originFilter,
                          width: 170,
                          options: [
                            _option('all', 'All quiz modes'),
                            _option('standard', 'Multiple choice'),
                            _option('writing', 'Writing'),
                            _option('mnemonic', 'Mnemonic'),
                          ],
                          onChanged: (v) => setState(() {
                            _originFilter = v ?? 'all'; _selectedKeys.clear();
                          })),
                        _dropdown(label: 'Sort by', value: _sort, width: 170,
                          options: [
                            _option('count', 'Most mistakes'),
                            _option('rate', 'Highest error rate'),
                            _option('recent', 'Most recent error'),
                            _option('category', 'Category'),
                            _option('az', 'Alphabetical'),
                          ],
                          onChanged: (v) => setState(() => _sort = v ?? 'count')),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Text('${visible.length} matching words',
                            style: theme.textTheme.bodyMedium),
                        const Spacer(),
                        TextButton(onPressed: visible.isEmpty ? null : () => setState(() {
                          _selectedKeys.addAll(visible.map((r) => r.key));
                        }), child: const Text('Select all')),
                        TextButton(onPressed: _selectedKeys.isEmpty ? null : () => setState(
                          () => _selectedKeys.clear()), child: const Text('Clear')),
                      ]),
                    ]),
                  )),
                  if (visible.isEmpty)
                    const SliverToBoxAdapter(child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No words match these filters.'),
                    )),
                  SliverList(delegate: SliverChildBuilderDelegate((context, i) {
                    final row = visible[i];
                    final checked = _selectedKeys.contains(row.key);
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (value) => setState(() {
                        if (value == true) { _selectedKeys.add(row.key); }
                        else { _selectedKeys.remove(row.key); }
                      }),
                      controlAffinity: ListTileControlAffinity.leading,
                      isThreeLine: true,
                      title: Text('${row.source}  →  ${row.target}',
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${row.topics.map(_topicName).join(' · ')}\n'
                          '${_wrongInFilter(row)} mistakes · ${row.attempts} attempts'),
                      secondary: Text('${(row.errorRate * 100).round()}%',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold)),
                    );
                  }, childCount: visible.length)),
                  const SliverToBoxAdapter(child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Older standard quiz results stored only totals, '
                        'so their individual wrong words cannot be reconstructed. '
                        'New attempts are tracked automatically.'),
                  )),
                ])),
                SafeArea(top: false, child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Row(children: [
                    Expanded(child: DropdownButtonFormField<String>(
                      value: _practiceMode,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Practice mode', border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        _option('standard', 'Multiple choice'),
                        _option('speaking', 'Speaking'),
                        _option('writing', 'Writing'),
                        _option('mnemonic', 'Mnemonic 3·2·1'),
                        _option('patterns', 'Pattern groups'),
                      ],
                      onChanged: (v) => setState(() => _practiceMode = v ?? 'standard'),
                    )),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: reviewCount == 0 ? null : () => _startReview(pair, visible),
                      icon: const Icon(Icons.play_arrow),
                      label: Text('Quiz ($reviewCount)'),
                    ),
                  ]),
                )),
              ]);
            },
          );
        },
      ),
    );
  }
}
