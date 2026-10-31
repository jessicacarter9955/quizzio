import 'package:flutter/material.dart';
import 'package:wordweaver/models/language_pair.dart';
import 'package:wordweaver/models/topic.dart';
import 'package:wordweaver/models/quiz_question.dart';
import 'package:wordweaver/services/vocabulary_service.dart';
import 'package:wordweaver/services/quiz_service.dart';
import 'package:wordweaver/services/user_service.dart';
import 'package:wordweaver/screens/quiz_results_page.dart';
import 'package:wordweaver/services/stats_service.dart';
import 'package:wordweaver/services/topic_service.dart';
import 'package:wordweaver/services/saved_words_service.dart';
import 'package:wordweaver/services/speech_service.dart';
import 'package:wordweaver/l10n/app_localizations.dart';

class QuizPage extends StatefulWidget {
  final LanguagePair languagePair;
  final List<Topic> selectedTopics;
  final int questionCount;
  final int answerOptionCount;
  final List<QuizQuestion>? initialQuestions;
  final bool speakingMode;

  const QuizPage({
    super.key,
    required this.languagePair,
    required this.selectedTopics,
    this.questionCount = 10,
    this.answerOptionCount = 3,
    this.initialQuestions,
    this.speakingMode = false,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<QuizQuestion>? questions;
  late Stopwatch stopwatch;
  int currentQuestionIndex = 0;
  int correctAnswers = 0;
  int incorrectAnswers = 0;
  String? selectedAnswer;
  bool hasAnswered = false;
  late final VocabularyService _vocabularyService;
  late final QuizService _quizService;
  List<String>? _currentShuffledAnswers;
  late final StatsService _statsService;
  late final TopicService _topicService;
  late final SavedWordsService _savedWordsService;
  late final SpeechService _speechService;
  bool _isSpeechListening = false;

  @override
  void initState() {
    super.initState();
    _vocabularyService = VocabularyService();
    _quizService = QuizService();
    _statsService = StatsService();
    _topicService = TopicService();
    _savedWordsService = SavedWordsService();
    _speechService = SpeechService();
    _prepareQuiz();
    stopwatch = Stopwatch()..start();
  }

  Future<void> _prepareQuiz() async {
    if (widget.initialQuestions != null) {
      setState(() {
        questions = widget.initialQuestions;
        if (questions != null && questions!.isNotEmpty) {
          final q = questions![0];
          _currentShuffledAnswers = [q.correctAnswer, ...q.wrongAnswers]
            ..shuffle();
        } else {
          _currentShuffledAnswers = null;
        }
      });
      return;
    }

    await _vocabularyService.ready; // ensure vocab is loaded
    final generated = _quizService.generateQuiz(
      widget.languagePair.key,
      widget.selectedTopics.map((t) => t.id).toList(),
      widget.questionCount,
      answerOptionCount: widget.answerOptionCount,
    );
    if (!mounted) return;
    setState(() {
      questions = generated;
      if (questions != null && questions!.isNotEmpty) {
        final q = questions![0];
        _currentShuffledAnswers = [q.correctAnswer, ...q.wrongAnswers]
          ..shuffle();
      } else {
        _currentShuffledAnswers = null;
      }
    });
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    if (value.length == 1) {
      return value.toUpperCase();
    }
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  String _normalizeSpoken(String input) {
    var result = input.trim().toLowerCase();
    const accentMap = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'ã': 'a',
      'å': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'ö': 'o',
      'õ': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
      'ñ': 'n',
    };
    final buffer = StringBuffer();
    for (final ch in result.split('')) {
      buffer.write(accentMap[ch] ?? ch);
    }
    return buffer.toString();
  }

  int _similarityScore(String a, String b) {
    final len = a.length < b.length ? a.length : b.length;
    var score = 0;
    for (var i = 0; i < len; i++) {
      if (a[i] == b[i]) score++;
    }
    return score;
  }

  void _applySpokenQuizAnswer(String spoken) {
    if (questions == null || questions!.isEmpty) return;
    final q = questions![currentQuestionIndex];
    final options =
        _currentShuffledAnswers ?? [q.correctAnswer, ...q.wrongAnswers];
    if (options.isEmpty) return;

    final spokenNorm = _normalizeSpoken(spoken);
    String best = options.first;
    var bestScore = -1;

    for (final opt in options) {
      final optNorm = _normalizeSpoken(opt);
      if (optNorm == spokenNorm) {
        best = opt;
        bestScore = 999;
        break;
      }
      final score = _similarityScore(optNorm, spokenNorm);
      if (score > bestScore) {
        bestScore = score;
        best = opt;
      }
    }

    handleAnswer(best);
  }

  Future<void> _startSpeechAnswer() async {
    if (hasAnswered || _isSpeechListening) return;
    final localeId = widget.languagePair.targetLanguage.code;
    setState(() {
      _isSpeechListening = true;
    });

    await _speechService.listen(
      localeId: localeId,
      onResult: (text, isFinal) {
        if (!mounted || !isFinal) return;
        final cleaned = text.trim();
        setState(() {
          _isSpeechListening = false;
        });
        if (cleaned.isEmpty) return;
        _applySpokenQuizAnswer(cleaned);
      },
    );
  }

  Future<void> _saveCurrentWord() async {
    if (questions == null || questions!.isEmpty) return;
    final q = questions![currentQuestionIndex];
    await _savedWordsService.addWord(
      sourceWord: q.word.sourceWord,
      targetWord: q.word.targetWord,
      languagePairKey: widget.languagePair.key,
      topic: q.topic,
    );
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.commonAddedToMyList),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void handleAnswer(String answer) {
    if (hasAnswered) return;
    final question = questions![currentQuestionIndex];
    final correct = answer == question.correctAnswer;
    setState(() {
      selectedAnswer = answer;
      hasAnswered = true;
      if (correct) {
        correctAnswers++;
      } else {
        incorrectAnswers++;
      }
    });
    _statsService.recordAnswer(
      isCorrect: correct,
      topicId: question.topic,
      languagePairKey: widget.languagePair.key,
    );
  }

  Future<void> nextQuestion() async {
    if (currentQuestionIndex < (questions!.length - 1)) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswer = null;
        hasAnswered = false;
        final q = questions![currentQuestionIndex];
        _currentShuffledAnswers = [q.correctAnswer, ...q.wrongAnswers]
          ..shuffle();
      });
    } else {
      stopwatch.stop();
      final userService = UserService();

      final result = _quizService.createResult(
        languagePairKey: widget.languagePair.key,
        topics: widget.selectedTopics.map((t) => t.id).toList(),
        correctAnswers: correctAnswers,
        incorrectAnswers: incorrectAnswers,
        timeTaken: stopwatch.elapsed.inSeconds,
      );

      await _quizService.saveQuizResult(result);
      await userService.updateWordsLearned(correctAnswers);
      await userService.recordQuizResults(
        questionsCount: questions!.length,
        correctCount: correctAnswers,
        incorrectCount: incorrectAnswers,
      );
      await _statsService.recordQuizEnd(
        totalQuestionsInQuiz: questions!.length,
        duration: stopwatch.elapsed,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => QuizResultsPage(result: result)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (questions == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.quizTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (questions!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.quizTitle)),
        body: Center(
          child: Text(
            l10n.quizNoQuestionsBody,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    final question = questions![currentQuestionIndex];
    final progress = (currentQuestionIndex + 1) / questions!.length;
    final requestedQuestions = widget.initialQuestions != null
        ? questions!.length
        : widget.questionCount;
    final actualQuestions = questions!.length;
    final reducedQuestions =
        widget.initialQuestions == null && actualQuestions < requestedQuestions;
    Topic? topic;
    try {
      topic = _topicService.topics.firstWhere((t) => t.id == question.topic);
    } catch (_) {
      topic = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.languagePair.sourceLanguage.name} Vocabulary',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n.quizQuestionLabel} ${currentQuestionIndex + 1}/${questions!.length}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              if (reducedQuestions) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.quizReducedQuestionsInfo(
                    actualQuestions,
                    requestedQuestions,
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    Theme.of(context).colorScheme.primary,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
              if (topic != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(topic.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        topic.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else
                const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      l10n.quizPromptHowDoYouSay(
                        _capitalize(question.word.sourceWord),
                        widget.languagePair.targetLanguage.name,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        height: 1.2,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (widget.speakingMode)
                    IconButton(
                      icon: Icon(
                        _isSpeechListening ? Icons.mic : Icons.mic_none,
                      ),
                      color: Theme.of(context).colorScheme.primary,
                      tooltip: 'Answer by speaking',
                      onPressed: hasAnswered ? null : _startSpeechAnswer,
                    ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_add_outlined),
                    color: Theme.of(context).colorScheme.primary,
                    tooltip: l10n.commonAddToMyList,
                    onPressed: _saveCurrentWord,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 8, top: 4),
                  children:
                      (_currentShuffledAnswers ??
                              [
                                question.correctAnswer,
                                ...question.wrongAnswers,
                              ])
                          .map((answer) {
                            final isCorrect = answer == question.correctAnswer;
                            final isSelected = answer == selectedAnswer;
                            Color? backgroundColor;
                            Color? borderColor;
                            Widget? trailing;

                            if (hasAnswered) {
                              if (isCorrect) {
                                backgroundColor = const Color(0xFFB8F76B);
                                borderColor = const Color(0xFF4B8D0F);
                                trailing = Icon(
                                  Icons.check_circle,
                                  color: const Color(0xFF28620A),
                                );
                              } else if (isSelected) {
                                backgroundColor = const Color(0xFFFFB8BC);
                                borderColor = const Color(0xFFCE2938);
                                trailing = Icon(
                                  Icons.cancel,
                                  color: const Color(0xFFC21D2D),
                                );
                              }
                            }

                            return AnswerOption(
                              answer: _capitalize(answer),
                              onTap: () => handleAnswer(answer),
                              backgroundColor: backgroundColor,
                              borderColor: borderColor,
                              textColor: hasAnswered && (isCorrect || isSelected)
                                  ? const Color(0xFF17240B)
                                  : null,
                              trailing: trailing,
                              isDisabled: hasAnswered,
                            );
                          })
                          .toList(),
                ),
              ),
              const SizedBox(height: 16),
              if (hasAnswered)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      l10n.commonNextQuestion,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnswerOption extends StatelessWidget {
  final String answer;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final Widget? trailing;
  final bool isDisabled;

  const AnswerOption({
    super.key,
    required this.answer,
    required this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.trailing,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 2)
            : null,
      ),
      child: ListTile(
        onTap: isDisabled ? null : onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          answer,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: textColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
        trailing:
            trailing ??
            Icon(
              Icons.circle_outlined,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

