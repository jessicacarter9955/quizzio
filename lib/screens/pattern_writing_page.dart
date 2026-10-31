import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordweaver/models/vocabulary_word.dart';

/// Pattern-driven written quiz. Recall hides the answer; Copy displays it.
/// Records are local, tied to the Wordweaver language direction and stable word identity.
class PatternWritingPage extends StatefulWidget {
  const PatternWritingPage({
    super.key, required this.words, required this.pairKey,
  });
  final List<VocabularyWord> words;
  final String pairKey;

  @override
  State<PatternWritingPage> createState() => _PatternWritingPageState();
}

class _PatternWritingPageState extends State<PatternWritingPage> {
  final TextEditingController _entry = TextEditingController();
  bool _copy = false, _checked = false;
  int _index = 0, _correct = 0, _wrong = 0;
  String _answer = '';

  @override
  void dispose() { _entry.dispose(); super.dispose(); }

  String _normalize(String s) => s.trim().toLowerCase()
    .replaceAll(RegExp(r'\s+'), ' ');

  Future<void> _check() async {
    if (_checked || _index >= widget.words.length) return;
    final w = widget.words[_index];
    final answer = _entry.text.trim();
    final correct = _normalize(answer) == _normalize(w.targetWord);
    final prefs = await SharedPreferences.getInstance();
    final key = 'wordweaver.pattern.writing.v1';
    List<dynamic> history;
    try { history = jsonDecode(prefs.getString(key) ?? '[]') as List<dynamic>; }
    catch (_) { history = []; }
    history.add({
      'pair': widget.pairKey, 'word': w.id, 'source': w.sourceWord,
      'target': w.targetWord, 'typed': answer, 'correct': correct,
      'mode': _copy ? 'copy' : 'recall',
      'at': DateTime.now().toIso8601String(),
    });
    if (history.length > 30000) history = history.sublist(history.length - 30000);
    await prefs.setString(key, jsonEncode(history));
    if (!mounted) return;
    setState(() {
      _checked = true;
      _answer = w.targetWord;
      if (correct) { _correct++; } else { _wrong++; }
    });
  }

  void _next() {
    setState(() { _index++; _entry.clear(); _checked = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_index >= widget.words.length) {
      return Scaffold(appBar: AppBar(title: const Text('Writing')),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_outline, size: 54),
            const SizedBox(height: 18),
            Text('Session complete', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text('$_correct correct · $_wrong to review'),
            const SizedBox(height: 24),
            FilledButton(onPressed: () => Navigator.pop(context),
              child: const Text('Back to Patterns')),
          ]),
        )));
    }
    final w = widget.words[_index];
    return Scaffold(
      appBar: AppBar(title: const Text('Writing'), centerTitle: true),
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('${_index + 1} / ${widget.words.length}', textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: _index / widget.words.length),
          const SizedBox(height: 20),
          Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
            ChoiceChip(label: const Text('Recall'), selected: !_copy,
              onSelected: _checked ? null : (_) => setState(() => _copy = false)),
            ChoiceChip(label: const Text('Copy'), selected: _copy,
              onSelected: _checked ? null : (_) => setState(() => _copy = true)),
          ]),
          const Spacer(),
          Text(w.sourceWord, textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium),
          if (_copy) ...[
            const SizedBox(height: 12),
            Text(w.targetWord, textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary)),
          ],
          const SizedBox(height: 28),
          TextField(
            controller: _entry,
            readOnly: _checked,
            autofocus: false,
            enableSuggestions: false,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Your translation',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _check(),
          ),
          if (_checked) ...[
            const SizedBox(height: 10),
            Text(
              _normalize(_entry.text) == _normalize(_answer)
                ? 'Correct' : 'Answer: $_answer',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ],
          const Spacer(),
          FilledButton(
            onPressed: _checked ? _next : _check,
            child: Text(_checked ? 'Next' : 'Check answer'),
          ),
        ]),
      )),
    );
  }
}
