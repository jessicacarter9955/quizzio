import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wordweaver/models/saved_word.dart';
import 'package:wordweaver/models/vocabulary_word.dart';
import 'package:wordweaver/models/quiz_question.dart';
import 'package:wordweaver/services/language_service.dart';
import 'package:wordweaver/services/quiz_service.dart';
import 'package:wordweaver/services/saved_words_service.dart';
import 'package:wordweaver/services/word_difficulty_service.dart';
import 'package:wordweaver/services/topic_service.dart';
import 'package:wordweaver/screens/quiz_page.dart';
import 'package:wordweaver/l10n/app_localizations.dart';

class MyListPage extends StatefulWidget {
  const MyListPage({super.key});

  @override
  State<MyListPage> createState() => _MyListPageState();
}

class _MyListPageState extends State<MyListPage> {
  late final SavedWordsService _savedService;
  late final LanguageService _languageService;
  late final TopicService _topicService;
  late final QuizService _quizService;
  final FlutterTts _tts = FlutterTts();
  late final WordDifficultyService _difficultyService;
  final Set<WordDifficulty> _difficultyFilters = {};
  String _topicFilter = 'all';

  @override
  void initState() {
    super.initState();
    _savedService = SavedWordsService();
    _difficultyService = WordDifficultyService();
    _languageService = LanguageService();
    _topicService = TopicService();
    _quizService = QuizService();
    _configureTts();
  }

  Future<void> _configureTts() async {
    final pair = _languageService.currentLanguagePair;
    if (pair != null) {
      await _tts.setLanguage(pair.targetLanguage.code);
    }
  }

  Future<void> _startQuizFromList(BuildContext context, List<SavedWord> words) async {
    final l10n = AppLocalizations.of(context);
    final pair = _languageService.currentLanguagePair;
    if (pair == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.myListSelectPairFirst),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (words.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.myListNotEnoughWords),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final allTopics = _topicService.topics;
    final topicIds = words.map((w) => w.topic as String).toSet();
    final selectedTopics = allTopics
        .where((t) => topicIds.contains(t.id))
        .toList();

    final shuffledWords = List.of(words)..shuffle();
    final answerOptionCount = _quizService.answerOptionCount;
    final questions = <QuizQuestion>[];

    for (final saved in shuffledWords) {
      final base = VocabularyWord(
        id: saved.id,
        sourceWord: saved.sourceWord,
        targetWord: saved.targetWord,
        languagePairKey: saved.languagePairKey,
        topic: saved.topic,
        createdAt: saved.addedAt,
      );
      final others = shuffledWords.where((w) => w.id != saved.id).toList();
      final sameTopic = others.where((w) => w.topic == saved.topic).toList();

      final candidates = <String>[];
      if (sameTopic.isNotEmpty) {
        candidates.addAll(sameTopic.map((w) => w.targetWord as String));
      }
      if (candidates.length < answerOptionCount) {
        candidates.addAll(
          others
              .where((w) => w.topic != base.topic)
              .map((w) => w.targetWord as String),
        );
      }

      final uniqueCandidates =
          candidates.where((t) => t != base.targetWord).toSet().toList()
            ..shuffle();

      final wrongAnswers = uniqueCandidates.take(answerOptionCount).toList();

      questions.add(
        QuizQuestion(
          word: base,
          options: [base.targetWord, ...wrongAnswers],
          correctIndex: 0,
          wrongAnswers: wrongAnswers,
          topic: base.topic,
        ),
      );

    }

    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.myListNotEnoughWords),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizPage(
          languagePair: pair,
          selectedTopics: selectedTopics,
          questionCount: questions.length,
          answerOptionCount: answerOptionCount,
          initialQuestions: questions,
        ),
      ),
    );
  }

  bool _matchesDifficulty(SavedWord word) =>
      !kIsWeb || _difficultyFilters.isEmpty ||
      _difficultyFilters.contains(_difficultyService.getDifficultyForParts(
        languagePairKey: word.languagePairKey,
        sourceWord: word.sourceWord,
        targetWord: word.targetWord,
      ));

  String _difficultyLabel(WordDifficulty difficulty) => switch (difficulty) {
    WordDifficulty.easy => 'Easy',
    WordDifficulty.medium => 'Medium',
    WordDifficulty.hard => 'Hard',
  };


  Color _difficultyColor(WordDifficulty? difficulty) => switch (difficulty) {
    WordDifficulty.easy => Colors.green,
    WordDifficulty.medium => Colors.amber,
    WordDifficulty.hard => Colors.red,
    null => Theme.of(context).colorScheme.outline,
  };


  Widget _difficultyFilterControls() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Difficulty', style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 4),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _difficultyFilters.isEmpty,
            onSelected: (_) => setState(() => _difficultyFilters.clear()),
          ),
          for (final difficulty in WordDifficulty.values)
            FilterChip(
              avatar: Icon(Icons.circle, size: 12, color: _difficultyColor(difficulty)),
              label: Text(_difficultyLabel(difficulty)),
              selected: _difficultyFilters.contains(difficulty),
              onSelected: (selected) => setState(() {
                if (selected) {
                  _difficultyFilters.add(difficulty);
                } else {
                  _difficultyFilters.remove(difficulty);
                }
              }),
            ),
        ],
      ),
    ],
  );


  Widget _difficultyMenu(SavedWord word) {
    final difficulty = _difficultyService.getDifficultyForParts(
      languagePairKey: word.languagePairKey,
      sourceWord: word.sourceWord,
      targetWord: word.targetWord,
    );
    return PopupMenuButton<String>(
      tooltip: 'Set difficulty',
      icon: Icon(difficulty == null ? Icons.circle_outlined : Icons.circle,
          size: 18, color: _difficultyColor(difficulty)),
      onSelected: (value) {
        final rating = value == 'clear' ? null : WordDifficulty.values.firstWhere(
          (option) => option.name == value,
        );
        _difficultyService.setDifficultyForParts(
          languagePairKey: word.languagePairKey,
          sourceWord: word.sourceWord,
          targetWord: word.targetWord,
          difficulty: rating,
        );
      },
      itemBuilder: (_) => [
        for (final option in WordDifficulty.values)
          PopupMenuItem<String>(
            value: option.name,
            child: Row(children: [
              Icon(Icons.circle, size: 14, color: _difficultyColor(option)),
              const SizedBox(width: 8),
              Text(_difficultyLabel(option)),
            ]),
          ),
        const PopupMenuItem<String>(
          value: 'clear', child: Text('Clear difficulty'),
        ),
      ],
    );
  }


  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  String _topicLabel(String topicId) {
    try {
      final t = _topicService.topics.firstWhere((x) => x.id == topicId);
      return '${t.emoji}  ${t.name}';
    } catch (_) {
      return topicId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.myListTitle,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            _savedService,
            _difficultyService,
            _languageService,
            _topicService,
          ]),
          builder: (context, _) {
            final pair = _languageService.currentLanguagePair;
            final allSaved = _savedService.savedWords;
            final filteredByPair = pair == null
                ? allSaved
                : allSaved.where((w) => w.languagePairKey == pair.key).toList();

            if (filteredByPair.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.myListEmptyTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.myListEmptyBody,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final topicsInList =
                filteredByPair.map((w) => w.topic).toSet().toList()..sort();

            final topicWords = (_topicFilter == 'all')
                ? filteredByPair
                : filteredByPair.where((w) => w.topic == _topicFilter).toList();
            final words = topicWords.where(_matchesDifficulty).toList();

            words.sort(
              (a, b) => a.targetWord.toLowerCase().compareTo(
                b.targetWord.toLowerCase(),
              ),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _topicFilter == 'all'
                              ? 'all'
                              : _topicFilter,
                          decoration: InputDecoration(
                            labelText: l10n.myListFilterByTopic,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text(l10n.myListAllTopics),
                            ),
                            ...topicsInList.map(
                              (id) => DropdownMenuItem(
                                value: id,
                                child: Text(_topicLabel(id)),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _topicFilter = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (kIsWeb)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: _difficultyFilterControls(),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: pair != null && words.length > 1
                          ? () => _startQuizFromList(context, words)
                          : null,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(l10n.myListQuizThisList),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    itemCount: words.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final w = words[index];
                      final topicLabel = _topicLabel(w.topic);
                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    w.targetWord,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    w.sourceWord,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.8),
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    topicLabel,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.7),
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.volume_up),
                              color: Theme.of(context).colorScheme.primary,
                              onPressed: () => _speak(w.targetWord),
                              tooltip: l10n.myListPlayPronunciation,
                            ),
                            if (kIsWeb) _difficultyMenu(w),
                            IconButton(
                              icon: Icon(kIsWeb ? Icons.star : Icons.delete_outline),
                              color: kIsWeb ? Colors.amber : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                              onPressed: () async {
                                await _savedService.removeWord(w.id);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.myListRemovedFromList),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              tooltip: l10n.myListRemoveFromList,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
