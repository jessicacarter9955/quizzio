import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wordweaver/models/language_pair.dart';
import 'package:wordweaver/models/topic.dart';
import 'package:wordweaver/models/quiz_question.dart';
import 'package:wordweaver/services/vocabulary_service.dart';
import 'package:wordweaver/services/quiz_service.dart';
import 'package:wordweaver/services/user_service.dart';
import 'package:wordweaver/services/stats_service.dart';
import 'package:wordweaver/services/topic_service.dart';
import 'package:wordweaver/services/speech_service.dart';
import 'package:wordweaver/services/grammar_practice_service.dart';
import 'package:wordweaver/services/word_mistake_service.dart';
import 'package:wordweaver/screens/quiz_results_page.dart';

class CompleteWordPage extends StatefulWidget {
  final LanguagePair languagePair;
  final List<Topic> selectedTopics;
  final int questionCount;
  final int answerOptionCount;
  final bool speakingMode;

  const CompleteWordPage({
    super.key,
    required this.languagePair,
    required this.selectedTopics,
    this.questionCount = 10,
    this.answerOptionCount = 3,
    this.speakingMode = false,
  });

  @override
  State<CompleteWordPage> createState() => _CompleteWordPageState();
}

class _CompleteWordPageState extends State<CompleteWordPage> {
  List<QuizQuestion>? questions;
  late Stopwatch stopwatch;
  int currentQuestionIndex = 0;
  int correctAnswers = 0;
  int incorrectAnswers = 0;
  late final VocabularyService _vocabularyService;
  late final QuizService _quizService;
  late final StatsService _statsService;
  late final TopicService _topicService;
  final TextEditingController _answerController = TextEditingController();
  List<bool> _revealed = [];
  bool hasAnswered = false;
  bool? lastAnswerCorrect;
  bool _ignoreAccents = true;
  Timer? _breakTimer;
  int _breakRemainingSeconds = 30;
  late final SpeechService _speechService;
  bool _isSpeechListening = false;

  @override
  void initState() {
    super.initState();
    _vocabularyService = VocabularyService();
    _quizService = QuizService();
    _statsService = StatsService();
    _topicService = TopicService();
    _speechService = SpeechService();
    _prepareQuiz();
    stopwatch = Stopwatch()..start();
  }

  @override
  void dispose() {
    _breakTimer?.cancel();
    _answerController.dispose();
    super.dispose();
  }

  String _target(QuizQuestion question) =>
      GrammarPracticeService().display(question.word, source: false);

  Future<void> _prepareQuiz() async {
    await Future.wait([_vocabularyService.ready, GrammarPracticeService().ready]);
    final generated = _quizService.generateQuiz(
      widget.languagePair.key,
      widget.selectedTopics.map((t) => t.id).toList(),
      widget.questionCount,
      answerOptionCount: widget.answerOptionCount,
    );
    if (!mounted) return;
    setState(() {
      questions = generated;
      currentQuestionIndex = 0;
      correctAnswers = 0;
      incorrectAnswers = 0;
      lastAnswerCorrect = null;
      _initRevealedForQuestion();
    });
  }

  void _initRevealedForQuestion() {
    if (questions == null || questions!.isEmpty) {
      _revealed = [];
      _answerController.clear();
      hasAnswered = false;
      lastAnswerCorrect = null;
      return;
    }
    final q = questions![currentQuestionIndex];
    final target = _target(q);
    _answerController.clear();
    hasAnswered = false;
    lastAnswerCorrect = null;
    final len = target.length;
    _revealed = List<bool>.filled(len, false);
    if (len > 0) {
      _revealed[0] = true;
    }
    if (len > 1) {
      _revealed[len - 1] = true;
    }
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    if (value.length == 1) {
      return value.toUpperCase();
    }
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  String _hintPattern() {
    if (questions == null || questions!.isEmpty) return '';
    final word = _target(questions![currentQuestionIndex]);
    if (word.isEmpty) return '';
    final buffer = StringBuffer();
    for (var i = 0; i < word.length; i++) {
      final ch = word[i];
      if (ch == ' ') {
        buffer.write('   ');
      } else {
        final isRevealed = i < _revealed.length && _revealed[i];
        buffer.write(isRevealed ? ch.toUpperCase() : '_');
      }
      if (i < word.length - 1) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }

  void _showBreakDialog() {
    _breakTimer?.cancel();
    setState(() {
      _breakRemainingSeconds = 30;
    });

    _breakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_breakRemainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _breakRemainingSeconds = 0;
        });
        Navigator.of(context, rootNavigator: true).maybePop();
      } else {
        setState(() {
          _breakRemainingSeconds--;
        });
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final total = 30.0;
        final remaining = _breakRemainingSeconds.toDouble().clamp(0, total);
        final progress = remaining / total;
        return AlertDialog(
          title: const Text('Take a break'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      '${_breakRemainingSeconds}s',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Short break time. In the future, an ad can be shown here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _breakTimer?.cancel();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    ).then((_) {
      _breakTimer?.cancel();
    });
  }

  void _revealNextLetter() {
    if (questions == null || questions!.isEmpty) return;
    final word = _target(questions![currentQuestionIndex]);
    for (var i = 0; i < word.length; i++) {
      final ch = word[i];
      if (ch == ' ') {
        continue;
      }
      if (i < _revealed.length && !_revealed[i]) {
        setState(() {
          _revealed[i] = true;
        });
        return;
      }
    }
  }

  void _revealFullWord() {
    if (questions == null || questions!.isEmpty) return;
    final word = _target(questions![currentQuestionIndex]);
    setState(() {
      _revealed = List<bool>.filled(word.length, true);
    });
  }

  String _normalizeForCompare(String input, {required bool stripAccents}) {
    var result = input.trim().toLowerCase();
    if (!stripAccents) return result;
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

  Future<void> _submitAnswer() async {
    if (questions == null || questions!.isEmpty) return;
    if (hasAnswered) return;
    final q = questions![currentQuestionIndex];
    final expected = _target(q);
    final given = _answerController.text;
    final expectedNorm = _normalizeForCompare(
      expected,
      stripAccents: _ignoreAccents,
    );
    final givenNorm = _normalizeForCompare(given, stripAccents: _ignoreAccents);
    final isCorrect = givenNorm == expectedNorm;
    setState(() {
      hasAnswered = true;
      lastAnswerCorrect = isCorrect;
      if (isCorrect) {
        correctAnswers++;
      } else {
        incorrectAnswers++;
      }
    });
    await _statsService.recordAnswer(
      isCorrect: isCorrect,
      topicId: q.topic,
      languagePairKey: widget.languagePair.key,
    );
    await WordMistakeService().recordAnswer(
      word: q.word, isCorrect: isCorrect, mode: 'writing',
    );
  }

  Future<void> _startSpeechAnswer() async {
    if (!widget.speakingMode) return;
    if (questions == null || questions!.isEmpty) return;
    if (hasAnswered || _isSpeechListening) return;
    final localeId = widget.languagePair.targetLanguage.code;

    setState(() {
      _isSpeechListening = true;
    });

    await _speechService.listen(
      localeId: localeId,
      onResult: (text, isFinal) async {
        if (!mounted || !isFinal) return;
        final cleaned = text.trim();
        setState(() {
          _isSpeechListening = false;
        });
        if (cleaned.isEmpty) return;
        _answerController.text = cleaned;
        await _submitAnswer();
      },
    );
  }

  Future<void> _finishQuiz() async {
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

  Future<void> _nextQuestion() async {
    if (questions == null || questions!.isEmpty) return;
    if (currentQuestionIndex < questions!.length - 1) {
      setState(() {
        currentQuestionIndex++;
        _initRevealedForQuestion();
      });
    } else {
      await _finishQuiz();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (questions == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Complete the Word'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (questions!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Complete the Word'),
          centerTitle: true,
        ),
        body: Center(
          child: Text(
            'No questions are available for the selected topics right now.\nTry picking more topics, a different language pair, or reducing the number of questions.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    final question = questions![currentQuestionIndex];
    final progress = (currentQuestionIndex + 1) / questions!.length;
    final requestedQuestions = widget.questionCount;
    final actualQuestions = questions!.length;
    final reducedQuestions = actualQuestions < requestedQuestions;
    Topic? topic;
    try {
      topic = _topicService.topics.firstWhere((t) => t.id == question.topic);
    } catch (_) {
      topic = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Complete the Word',
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
              if (topic != null) ...[
                Row(
                  children: [
                    Text(topic.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      topic.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Question ${currentQuestionIndex + 1}/${questions!.length}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              if (reducedQuestions) ...[
                const SizedBox(height: 4),
                Text(
                  'Only $actualQuestions of $requestedQuestions questions were available for the selected topics.',
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
              const SizedBox(height: 24),
              Text(
                "How do you write '${_capitalize(GrammarPracticeService().display(question.word, source: true))}' in ${widget.languagePair.targetLanguage.name}?",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  _hintPattern(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    letterSpacing: 4,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _answerController,
                enabled: !hasAnswered,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => hasAnswered ? null : _submitAnswer(),
                decoration: InputDecoration(
                  labelText: 'Your answer',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (widget.speakingMode) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(_isSpeechListening ? Icons.mic : Icons.mic_none),
                    color: Theme.of(context).colorScheme.primary,
                    tooltip: 'Answer by speaking',
                    onPressed: hasAnswered ? null : _startSpeechAnswer,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _ignoreAccents,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _ignoreAccents = value;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ignore accents (è = e)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: hasAnswered ? null : _revealNextLetter,
                      icon: const Icon(Icons.lightbulb_outline),
                      label: const Text('Reveal letter'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: hasAnswered ? null : _revealFullWord,
                      icon: const Icon(Icons.spellcheck),
                      label: const Text('Reveal word'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (lastAnswerCorrect != null)
                Text(
                  lastAnswerCorrect!
                      ? 'Correct!'
                      : "Correct answer: ${_target(question)}",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: lastAnswerCorrect!
                        ? const Color(0xFF28620A)
                        : Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _showBreakDialog,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Take a break',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: hasAnswered ? _nextQuestion : _submitAnswer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        hasAnswered
                            ? (currentQuestionIndex < questions!.length - 1
                                  ? 'Next Question'
                                  : 'Finish')
                            : 'Check Answer',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
