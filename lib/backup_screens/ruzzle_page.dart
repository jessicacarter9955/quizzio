import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wordweaver/l10n/app_localizations.dart';
import 'package:wordweaver/models/language_pair.dart';
import 'package:wordweaver/models/topic.dart';
import 'package:wordweaver/models/vocabulary_word.dart';
import 'package:wordweaver/services/quiz_service.dart';
import 'package:wordweaver/services/stats_service.dart';
import 'package:wordweaver/services/topic_service.dart';
import 'package:wordweaver/services/user_service.dart';
import 'package:wordweaver/services/vocabulary_service.dart';

class RuzzlePage extends StatefulWidget {
  final LanguagePair languagePair;
  final List<Topic> selectedTopics;

  const RuzzlePage({
    super.key,
    required this.languagePair,
    required this.selectedTopics,
  });

  @override
  State<RuzzlePage> createState() => _RuzzlePageState();
}

class _RuzzlePageState extends State<RuzzlePage> {
  static const int _gridSize = 4;
  static const int _maxRounds = 8;

  final VocabularyService _vocab = VocabularyService();
  final TopicService _topicService = TopicService();
  final StatsService _statsService = StatsService();
  final QuizService _quizService = QuizService();
  final UserService _userService = UserService();

  final math.Random _rng = math.Random();

  List<VocabularyWord> _words = [];
  int _roundIndex = 0;

  VocabularyWord? _currentWord;
  String _gridTarget = '';
  List<String> _gridLetters = List<String>.filled(_gridSize * _gridSize, '');
  List<int> _solutionPath = [];

  List<int> _selectedPath = [];
  Set<int> _selectedSet = {};
  bool _hintUsed = false;

  int _totalScore = 0;
  int _solvedCount = 0;
  final Stopwatch _gameWatch = Stopwatch();
  final Stopwatch _wordWatch = Stopwatch();

  bool _loading = true;
  bool _noWords = false;

  @override
  void initState() {
    super.initState();
    _prepareGame();
  }

  Future<void> _prepareGame() async {
    await _vocab.ready;
    final pair = widget.languagePair;
    final topics = widget.selectedTopics.isNotEmpty
        ? widget.selectedTopics
        : _topicService.topics;
    final topicIds = topics.map((t) => t.id).toList();
    final words = _vocab.getWordsForQuiz(pair.key, topicIds, _maxRounds * 2);

    if (!mounted) return;

    if (words.isEmpty) {
      setState(() {
        _loading = false;
        _noWords = true;
      });
      return;
    }

    _words = words;
    _roundIndex = 0;
    _totalScore = 0;
    _solvedCount = 0;
    _gameWatch
      ..reset()
      ..start();

    await _loadRound();
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  Future<void> _loadRound() async {
    if (_roundIndex >= _maxRounds || _roundIndex >= _words.length) {
      await _finishGame();
      return;
    }

    final word = _words[_roundIndex];
    final cleaned = _cleanTarget(word.targetWord);
    if (cleaned.length < 2 || cleaned.length > _gridSize * _gridSize) {
      _roundIndex++;
      await _loadRound();
      return;
    }

    final path = _buildPath(cleaned.length);
    if (path == null) {
      _roundIndex++;
      await _loadRound();
      return;
    }

    final size = _gridSize * _gridSize;
    final letters = List<String>.filled(size, '');
    for (var i = 0; i < cleaned.length; i++) {
      letters[path[i]] = cleaned[i];
    }

    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for (var i = 0; i < size; i++) {
      if (letters[i].isEmpty) {
        letters[i] = alphabet[_rng.nextInt(alphabet.length)];
      }
    }

    _currentWord = word;
    _gridTarget = cleaned;
    _gridLetters = letters;
    _solutionPath = path;
    _selectedPath = [];
    _selectedSet = {};
    _hintUsed = false;
    _wordWatch
      ..reset()
      ..start();

    setState(() {});
  }

  String _cleanTarget(String value) {
    final upper = value.toUpperCase();
    final buffer = StringBuffer();
    for (final ch in upper.split('')) {
      if (ch.codeUnitAt(0) >= 65 && ch.codeUnitAt(0) <= 90) {
        buffer.write(ch);
      }
    }
    return buffer.toString();
  }

  List<int>? _buildPath(int length) {
    final size = _gridSize * _gridSize;
    if (length <= 0 || length > size) return null;

    for (var attempt = 0; attempt < 200; attempt++) {
      final path = <int>[];
      var current = _rng.nextInt(size);
      path.add(current);
      var failed = false;
      for (var i = 1; i < length; i++) {
        final neighbors = _neighbors(
          current,
        ).where((n) => !path.contains(n)).toList();
        if (neighbors.isEmpty) {
          failed = true;
          break;
        }
        current = neighbors[_rng.nextInt(neighbors.length)];
        path.add(current);
      }
      if (!failed) return path;
    }
    return null;
  }

  Iterable<int> _neighbors(int index) sync* {
    final row = index ~/ _gridSize;
    final col = index % _gridSize;
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = row + dr;
        final nc = col + dc;
        if (nr < 0 || nr >= _gridSize || nc < 0 || nc >= _gridSize) continue;
        yield nr * _gridSize + nc;
      }
    }
  }

  int? _indexFromOffset(Offset offset, double cellSize) {
    final row = (offset.dy / cellSize).floor();
    final col = (offset.dx / cellSize).floor();
    if (row < 0 || row >= _gridSize || col < 0 || col >= _gridSize) {
      return null;
    }
    return row * _gridSize + col;
  }

  void _startPath(Offset position, double cellSize) {
    final index = _indexFromOffset(position, cellSize);
    if (index == null) return;
    _selectedPath = [index];
    _selectedSet = {index};
    setState(() {});
  }

  void _extendPath(Offset position, double cellSize) {
    if (_selectedPath.isEmpty) {
      _startPath(position, cellSize);
      return;
    }

    final last = _selectedPath.last;
    final lastRow = last ~/ _gridSize;
    final lastCol = last % _gridSize;
    final lastCenter = Offset(
      (lastCol + 0.5) * cellSize,
      (lastRow + 0.5) * cellSize,
    );

    final dx = position.dx - lastCenter.dx;
    final dy = position.dy - lastCenter.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final minDistance = cellSize * 0.55;

    if (distance < minDistance) return;

    final nx = dx / distance;
    final ny = dy / distance;

    int stepRow;
    int stepCol;

    if (nx.abs() < 0.4 && ny.abs() >= 0.8) {
      stepRow = ny > 0 ? 1 : -1;
      stepCol = 0;
    } else if (ny.abs() < 0.4 && nx.abs() >= 0.8) {
      stepRow = 0;
      stepCol = nx > 0 ? 1 : -1;
    } else {
      stepRow = ny > 0 ? 1 : -1;
      stepCol = nx > 0 ? 1 : -1;
    }

    final nr = lastRow + stepRow;
    final nc = lastCol + stepCol;
    if (nr < 0 || nr >= _gridSize || nc < 0 || nc >= _gridSize) return;
    final index = nr * _gridSize + nc;

    if (_selectedSet.contains(index)) return;

    _selectedPath.add(index);
    _selectedSet.add(index);
    setState(() {});
  }

  Future<void> _tapCell(int index) async {
    if (index < 0 || index >= _gridLetters.length) return;
    if (_gridTarget.isEmpty) return;

    if (_selectedPath.length >= _gridTarget.length) return;

    final newPath = List<int>.from(_selectedPath);
    final newSet = Set<int>.from(_selectedSet);

    if (newPath.isEmpty) {
      newPath.add(index);
      newSet.add(index);
    } else {
      if (newSet.contains(index)) return;
      newPath.add(index);
      newSet.add(index);
    }

    setState(() {
      _selectedPath = newPath;
      _selectedSet = newSet;
    });

    if (_selectedPath.length == _gridTarget.length) {
      await _endPath(fromTap: true);
    }
  }

  Future<void> _endPath({bool fromTap = false}) async {
    if (_selectedPath.isEmpty || _gridTarget.isEmpty) {
      _selectedPath = [];
      _selectedSet = {};
      setState(() {});
      return;
    }
    final buffer = StringBuffer();
    for (final i in _selectedPath) {
      buffer.write(_gridLetters[i]);
    }
    final attempt = buffer.toString();
    if (attempt == _gridTarget) {
      await _handleSolved();
    } else {
      if (!fromTap) {
        _selectedPath = [];
        _selectedSet = {};
      }
      setState(() {});
    }
  }

  Future<void> _handleSolved() async {
    _wordWatch.stop();
    final seconds = _wordWatch.elapsed.inSeconds;
    final length = _gridTarget.length;
    const base = 50;
    final lengthBonus = 10 * length;
    final speedBonus = math.max(0, 80 - 4 * seconds);
    final multiplier = _hintUsed ? 0.5 : 1.0;
    final score = ((base + lengthBonus + speedBonus) * multiplier).round();

    final word = _currentWord;
    if (word != null) {
      _totalScore += score;
      _solvedCount++;
      await _statsService.recordAnswer(
        isCorrect: true,
        topicId: word.topic,
        languagePairKey: widget.languagePair.key,
      );
      await _userService.updateWordsLearned(1);
    }

    _selectedPath = [];
    _selectedSet = {};
    _roundIndex++;
    await _loadRound();
  }

  Future<void> _skipWord() async {
    _wordWatch.stop();
    final word = _currentWord;
    final correct = word?.targetWord ?? _gridTarget;

    if (word != null) {
      await _statsService.recordAnswer(
        isCorrect: false,
        topicId: word.topic,
        languagePairKey: widget.languagePair.key,
      );
    }

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Skipped'),
          content: Text('The correct word was: $correct'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    _selectedPath = [];
    _selectedSet = {};
    _roundIndex++;
    await _loadRound();
  }

  Future<void> _finishGame() async {
    _gameWatch.stop();
    final totalQuestions = _roundIndex;
    if (totalQuestions <= 0) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final incorrect = totalQuestions - _solvedCount;

    await _statsService.recordQuizEnd(
      totalQuestionsInQuiz: totalQuestions,
      duration: _gameWatch.elapsed,
    );

    final result = _quizService.createResult(
      languagePairKey: widget.languagePair.key,
      topics: widget.selectedTopics.map((t) => t.id).toList(),
      correctAnswers: _solvedCount,
      incorrectAnswers: incorrect,
      timeTaken: _gameWatch.elapsed.inSeconds,
    );
    await _quizService.saveQuizResult(result);

    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    final scoreLabel = l10n?.commonScore ?? 'Score';
    final accuracyLabel = l10n?.commonAccuracy ?? 'Accuracy';
    final accuracy = totalQuestions == 0
        ? 0.0
        : (_solvedCount / totalQuestions * 100.0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Round Complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$scoreLabel: $_totalScore'),
              const SizedBox(height: 8),
              Text(
                '$accuracyLabel: ${accuracy.toStringAsFixed(0)}%  ·  $_solvedCount/$totalQuestions',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Back to Home'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _loading = true;
                  _noWords = false;
                });
                _prepareGame();
              },
              child: const Text('Play Again'),
            ),
          ],
        );
      },
    );
  }

  void _useHint() {
    if (_gridTarget.isEmpty) return;
    if (_hintUsed) return;
    if (_solutionPath.isEmpty) return;
    setState(() {
      _hintUsed = true;
      _selectedPath = List<int>.from(_solutionPath);
      _selectedSet = _solutionPath.toSet();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedPath = [];
      _selectedSet = {};
    });
  }

  String get _currentSelectionString {
    if (_selectedPath.isEmpty) return '';
    final buffer = StringBuffer();
    for (final i in _selectedPath) {
      buffer.write(_gridLetters[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final pair = widget.languagePair;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final questionStyle = textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurface,
    );
    final buttonTextStyle = questionStyle?.copyWith(
      fontSize: textTheme.titleMedium?.fontSize ?? questionStyle.fontSize,
    );

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Ruzzle',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_noWords || _currentWord == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Ruzzle',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No words available for this language pair and topics.\nTry selecting more topics or another pair.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    final questionLabel = l10n?.quizQuestionLabel ?? 'Question';
    final targetLangName = pair.targetLanguage.name;
    final prompt =
        l10n?.quizPromptHowDoYouSay(_currentWord!.sourceWord, targetLangName) ??
        'How do you say "${_currentWord!.sourceWord}" in $targetLangName?';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ruzzle',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$questionLabel ${_roundIndex + 1}/${math.min(_maxRounds, _words.length)}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    'Score: $_totalScore',
                    style: buttonTextStyle?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                prompt,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: questionStyle,
              ),
              const SizedBox(height: 8),
              Text(
                _currentSelectionString.isEmpty
                    ? 'Find the translation in the grid'
                    : _currentSelectionString,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final boardExtent = math.min(
                      constraints.maxWidth,
                      constraints.maxHeight - 40,
                    );
                    final cellSize = boardExtent / _gridSize;
                    return Center(
                      child: SizedBox(
                        width: boardExtent,
                        height: boardExtent,
                        child: GestureDetector(
                          onPanStart: (details) =>
                              _startPath(details.localPosition, cellSize),
                          onPanUpdate: (details) =>
                              _extendPath(details.localPosition, cellSize),
                          onPanEnd: (_) => _endPath(),
                          onPanCancel: _endPath,
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: _gridSize,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemCount: _gridLetters.length,
                            itemBuilder: (context, index) {
                              final letter = _gridLetters[index];
                              final inPath = _selectedSet.contains(index);
                              final inHint =
                                  _hintUsed && _solutionPath.contains(index);

                              var bg = Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest;
                              var border = Theme.of(
                                context,
                              ).colorScheme.outlineVariant;
                              var textColor = Theme.of(
                                context,
                              ).colorScheme.onSurface;

                              if (inHint) {
                                bg = Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.15);
                                border = Theme.of(context).colorScheme.primary;
                                textColor = Theme.of(
                                  context,
                                ).colorScheme.primary;
                              }
                              if (inPath) {
                                bg = Theme.of(
                                  context,
                                ).colorScheme.tertiary.withValues(alpha: 0.2);
                                border = Theme.of(context).colorScheme.tertiary;
                                textColor = Theme.of(
                                  context,
                                ).colorScheme.tertiary;
                              }

                              return GestureDetector(
                                onTap: () => _tapCell(index),
                                child: Container(
                                  margin: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: border, width: 2),
                                  ),
                                  child: Center(
                                    child: Text(
                                      letter,
                                      style: textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _useHint,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text('Hint', style: buttonTextStyle),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearSelection,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text('Clear', style: buttonTextStyle),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _skipWord,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Skip',
                        style: buttonTextStyle?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimary,
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
