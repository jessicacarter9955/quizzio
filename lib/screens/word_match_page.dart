import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:wordweaver/services/language_service.dart';
import 'package:wordweaver/services/topic_service.dart';
import 'package:wordweaver/services/vocabulary_service.dart';
import 'package:wordweaver/models/vocabulary_word.dart';

class WordMatchPage extends StatefulWidget {
  const WordMatchPage({super.key});

  @override
  State<WordMatchPage> createState() => _WordMatchPageState();
}

class _WordMatchPageState extends State<WordMatchPage> {
  final _vocab = VocabularyService();
  final _lang = LanguageService();
  final _topics = TopicService();

  List<_CardModel> _leftCards = [];
  List<_CardModel> _rightCards = [];
  final Set<String> _matchedIds = {};
  late Stopwatch _stopwatch;
  Timer? _ticker;
  int? _draggingRightIndex;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _prepareGame();
  }

  Future<List<_CardModel>?> _loadTestItems() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/data/word_match_test.json',
      );
      if (raw.isEmpty) return null;
      final Map<String, dynamic> decoded = Map<String, dynamic>.from(
        jsonDecode(raw) as Map,
      );
      final List items = decoded['items'] as List? ?? const [];
      if (items.length < 3) return null;
      final subset = items.take(6).toList();
      final models = <_CardModel>[];
      for (final item in subset) {
        final map = Map<String, dynamic>.from(item as Map);
        final emoji = (map['emoji'] as String?) ?? '🔤';
        final label = (map['label'] as String?) ?? '';
        if (label.isEmpty) continue;
        final id = '${label}_$emoji';
        models.add(_CardModel(id: id, emoji: emoji, label: label));
      }
      if (models.length < 3) return null;
      return models;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _prepareGame() async {
    await _vocab.ready; // ensure vocab is loaded
    final pair = _lang.currentLanguagePair;
    final selected = _topics.getSelectedTopics();
    if (pair == null) {
      setState(() {
        _leftCards = [];
        _rightCards = [];
        _matchedIds.clear();
      });
      return;
    }
    // Prefer test JSON if present
    final testModels = await _loadTestItems();
    final rnd = Random();
    List<_CardModel> left;
    List<_CardModel> right;

    if (testModels != null && testModels.isNotEmpty) {
      // Use test items: same label on both sides
      left = List<_CardModel>.from(testModels);
      right = testModels
          .map((m) => _CardModel(id: m.id, emoji: m.emoji, label: m.label))
          .toList();
      // Sort left alphabetically (source language), shuffle right
      left.sort(
        (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
      );
      right.shuffle(rnd);
    } else {
      // Use selected topics or fallback to all
      final topicIds = (selected.isEmpty ? _topics.topics : selected)
          .map((t) => t.id)
          .toList();
      // Get 6 words for pairs
      final words = _vocab.getWordsForQuiz(pair.key, topicIds, 6);
      // Map by topic emoji
      final topicEmoji = {for (final t in _topics.topics) t.id: t.emoji};
      final chosen = words.take(6).toList();
      // If fewer than 6 from vocab, pad with simple placeholders to keep the game playable
      while (chosen.length < 6) {
        chosen.add(
          VocabularyWord(
            id: 'pad-${chosen.length}-${DateTime.now().millisecondsSinceEpoch}',
            sourceWord: 'Word${chosen.length + 1}',
            targetWord: 'Word${chosen.length + 1}',
            languagePairKey: pair.key,
            topic: _topics.topics.isNotEmpty
                ? _topics.topics[rnd.nextInt(_topics.topics.length)].id
                : 'misc',
            createdAt: DateTime.now(),
          ),
        );
      }

      left = <_CardModel>[];
      right = <_CardModel>[];
      for (final w in chosen) {
        final emoji = topicEmoji[w.topic] ?? '🔤';
        left.add(_CardModel(id: w.id, emoji: emoji, label: w.sourceWord));
        right.add(_CardModel(id: w.id, emoji: emoji, label: w.targetWord));
      }
      // Sort left alphabetically (source language), shuffle right
      left.sort(
        (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
      );
      right.shuffle(rnd);
    }

    setState(() {
      _leftCards = left;
      _rightCards = right;
      _matchedIds.clear();
      _stopwatch.reset();
      _stopwatch.start();
    });
  }

  void _reorderRight(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;
    setState(() {
      if (fromIndex < toIndex) {
        toIndex -= 1;
      }
      final item = _rightCards.removeAt(fromIndex);
      _rightCards.insert(toIndex, item);
    });
    _checkSolved();
  }

  void _checkSolved() {
    if (_leftCards.isEmpty || _leftCards.length != _rightCards.length) return;
    for (var i = 0; i < _leftCards.length; i++) {
      if (_leftCards[i].id != _rightCards[i].id) {
        return;
      }
    }

    _stopwatch.stop();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Great Job!'),
          content: Text('You ordered all pairs in ${_elapsed}s'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _prepareGame();
              },
              child: const Text('Play Again'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    });
  }

  int get _elapsed => _stopwatch.elapsed.inSeconds;
  String _fmt(int totalSec) {
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Word Match',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(onPressed: _prepareGame, icon: const Icon(Icons.refresh)),
        ],
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 18,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _fmt(_elapsed),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Drag the translations on the right to match the words on the left.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: List.generate(_leftCards.length, (i) {
                          final card = _leftCards[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _MatchCard(
                              emoji: card.emoji,
                              label: card.label,
                              selected: false,
                              onTap: () {},
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: List.generate(_rightCards.length, (i) {
                          final card = _rightCards[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Draggable<int>(
                              data: i,
                              dragAnchorStrategy: pointerDragAnchorStrategy,
                              feedback: Material(
                                color: Colors.transparent,
                                child: _MatchCard(
                                  emoji: '',
                                  label: card.label,
                                  selected: true,
                                  onTap: () {},
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.3,
                                child: _MatchCard(
                                  emoji: '',
                                  label: card.label,
                                  selected: false,
                                  onTap: () {},
                                ),
                              ),
                              onDragStarted: () {
                                setState(() => _draggingRightIndex = i);
                              },
                              onDragEnd: (_) {
                                setState(() => _draggingRightIndex = null);
                              },
                              child: DragTarget<int>(
                                onWillAcceptWithDetails: (from) => from != i,
                                onAcceptWithDetails: (details) {
                                  final fromIndex = details.data;
                                  _reorderRight(fromIndex, i);
                                },
                                builder: (context, candidate, rejected) {
                                  final highlight =
                                      candidate.isNotEmpty ||
                                      _draggingRightIndex == i;
                                  return _MatchCard(
                                    emoji: '',
                                    label: card.label,
                                    selected: highlight,
                                    onTap: () {},
                                  );
                                },
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardModel {
  final String id;
  final String emoji;
  final String label;
  _CardModel({required this.id, required this.emoji, required this.label});
  _CardModel.copyOf(_CardModel other)
    : id = other.id,
      emoji = other.emoji,
      label = other.label;
}

class _MatchCard extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MatchCard({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = selected
        ? colorScheme.primary.withValues(alpha: 0.10)
        : colorScheme.surface;
    final borderColor = selected
        ? colorScheme.primary
        : colorScheme.outlineVariant;
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.4),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: textStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
