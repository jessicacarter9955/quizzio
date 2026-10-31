import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordweaver/models/vocabulary_word.dart';
import 'package:wordweaver/services/pattern_engine.dart';
import 'package:wordweaver/services/stats_service.dart';
import 'package:wordweaver/services/quiz_service.dart';
import 'package:wordweaver/services/word_mistake_service.dart';

/// 3·2·1 spaced recall: three successful recalls, then two at the next
/// weekly checkpoint, then one at the final checkpoint. Failed recall restarts.
/// Practice history is stored locally and survives restarts on web and mobile.
class PatternMnemonicPage extends StatefulWidget {
  const PatternMnemonicPage({
    super.key, required this.words, required this.pairKey,
    this.forcePractice = false,
  });
  final List<VocabularyWord> words;
  final String pairKey;
  /// Review selected mistakes now, even if their 3·2·1 due date is later.
  final bool forcePractice;

  @override
  State<PatternMnemonicPage> createState() => _PatternMnemonicPageState();
}

class _PatternMnemonicPageState extends State<PatternMnemonicPage> {
  static const storeKey = 'wordweaver.mnemonic.321.v1';
  Map<String, dynamic> _saved = {};
  int _index = 0;
  bool _showAnswer = false;
  bool _loaded = false;
  int _correct = 0, _wrong = 0;
  bool _sessionClosed = false;
  final Stopwatch _stopwatch = Stopwatch()..start();
  final Set<String> _practiceReviewed = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    try { _saved = jsonDecode(prefs.getString(storeKey) ?? '{}') as Map<String, dynamic>; }
    catch (_) { _saved = {}; }
    if (mounted) setState(() => _loaded = true);
  }

  String _key(VocabularyWord w) => PatternEngine.identity(w);
  Map<String, dynamic> _review(VocabularyWord w) {
    final saved = _saved[_key(w)];
    return saved is Map<String, dynamic>
        ? saved : <String, dynamic>{'stage': 0, 'hits': 0, 'due': null};
  }

  bool _due(VocabularyWord w) {
    if (widget.forcePractice) return !_practiceReviewed.contains(_key(w));
    final r = _review(w);
    final due = DateTime.tryParse((r['due'] ?? '').toString());
    return (r['stage'] ?? 0) < 3 &&
        (due == null || !due.isAfter(DateTime.now()));
  }

  List<VocabularyWord> get _pending =>
      widget.words.where(_due).toList();

  Future<void> _rate(bool remembered) async {
    final pending = _pending;
    if (pending.isEmpty) return;
    final word = pending[_index.clamp(0, pending.length - 1)];
    final r = Map<String, dynamic>.from(_review(word));
    var stage = (r['stage'] as num?)?.toInt() ?? 0;
    var hits = (r['hits'] as num?)?.toInt() ?? 0;
    if (!remembered) {
      stage = 0; hits = 0;
      r['due'] = DateTime.now().add(const Duration(minutes: 5)).toIso8601String();
    } else if (stage < 3) {
      hits++;
      const targets = [3, 2, 1];
      if (hits >= targets[stage.clamp(0, 2)]) {
        stage++; hits = 0;
        r['due'] = stage == 3 ? null :
          DateTime.now().add(Duration(days: stage == 1 ? 7 : 14)).toIso8601String();
      } else {
        r['due'] = null;
      }
    }
    r['stage'] = stage; r['hits'] = hits;
    _saved[_key(word)] = r;
    if (widget.forcePractice) _practiceReviewed.add(_key(word));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storeKey, jsonEncode(_saved));
    if (remembered) { _correct++; } else { _wrong++; }
    await StatsService().recordAnswer(
      isCorrect: remembered,
      topicId: word.topic,
      languagePairKey: widget.pairKey,
    );
    await WordMistakeService().recordAnswer(
      word: word, isCorrect: remembered, mode: 'mnemonic');
    if (_pending.isEmpty && !_sessionClosed) {
      _sessionClosed = true;
      _stopwatch.stop();
      await StatsService().recordQuizEnd(
        totalQuestionsInQuiz: _correct + _wrong,
        duration: _stopwatch.elapsed,
      );
      await QuizService().saveQuizResult(QuizService().createResult(
        languagePairKey: widget.pairKey,
        topics: widget.words.map((w) => w.topic).toSet().toList(),
        correctAnswers: _correct,
        incorrectAnswers: _wrong,
        timeTaken: _stopwatch.elapsed.inSeconds,
      ));
    }
    if (!mounted) return;
    setState(() {
      _showAnswer = false;
      final next = _pending;
      if (next.isEmpty) _index = 0;
      else _index = _index % next.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final pending = _pending;
    final done = widget.words.where((w) => (_review(w)['stage'] ?? 0) == 3).length;
    final waiting = widget.forcePractice
        ? 0 : widget.words.length - pending.length - done;
    final current = pending.isEmpty ? null : pending[_index.clamp(0, pending.length - 1)];
    final stage = current == null ? 0 : (_review(current)['stage'] as num?)?.toInt() ?? 0;
    final hits = current == null ? 0 : (_review(current)['hits'] as num?)?.toInt() ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Mnemonic · 3·2·1'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('${widget.words.length} selected · $done mastered · $waiting scheduled',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            if (current == null) ...[
              const Spacer(),
              const Icon(Icons.check_circle_outline, size: 52),
              const SizedBox(height: 16),
              Text(widget.forcePractice ? 'Review complete' : 'All due cards reviewed',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(widget.forcePractice
                  ? 'You reviewed all the selected difficult words.'
                  : 'The next 3·2·1 stage becomes available on its review date.',
                textAlign: TextAlign.center),
              const Spacer(),
            ] else ...[
              Text('Card ${_index + 1} of ${pending.length} · Stage ${stage + 1}/3 · $hits recalled',
                textAlign: TextAlign.center, style: theme.textTheme.labelLarge),
              const SizedBox(height: 18),
              Expanded(child: Card(
                elevation: 0,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => _showAnswer = true),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(current.sourceWord, textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 24),
                        if (_showAnswer)
                          Text(current.targetWord, textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.primary))
                        else
                          Text('Tap to reveal translation',
                            style: theme.textTheme.bodySmall),
                      ]),
                  ),
                ),
              )),
              const SizedBox(height: 16),
              if (!_showAnswer)
                FilledButton(onPressed: () => setState(() => _showAnswer = true),
                  child: const Text('Reveal answer'))
              else Row(children: [
                Expanded(child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB8BC),
                    foregroundColor: const Color(0xFF711622),
                  ),
                  onPressed: () => _rate(false), child: const Text('Again'))),
                const SizedBox(width: 12),
                Expanded(child: FilledButton(
                  onPressed: () => _rate(true), child: const Text('Remembered'))),
              ]),
              const SizedBox(height: 16),
            ],
          ]),
        ),
      ),
    );
  }
}

