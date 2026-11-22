import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wordweaver/models/language_pair.dart';
import 'package:wordweaver/models/vocabulary_word.dart';
import 'package:wordweaver/models/quiz_question.dart';
import 'package:wordweaver/services/language_service.dart';
import 'package:wordweaver/services/pattern_catalog.dart';
import 'package:wordweaver/services/pattern_engine.dart';
import 'package:wordweaver/services/saved_words_service.dart';
import 'package:wordweaver/services/word_difficulty_service.dart';
import 'package:wordweaver/services/topic_service.dart';
import 'package:wordweaver/services/quiz_selection.dart';
import 'package:wordweaver/services/vocabulary_service.dart';
import 'package:wordweaver/services/grammar_practice_service.dart';
import 'package:wordweaver/screens/quiz_page.dart';
import 'package:wordweaver/screens/language_setup_page.dart';
import 'package:wordweaver/screens/pattern_mnemonic_page.dart';
import 'package:wordweaver/screens/pattern_writing_page.dart';

/// One shared, native Material 3 interface on Android and Flutter Web.
/// Wordweaver's existing palette, navigation and settings are preserved.
class PatternScreen extends StatefulWidget {
  const PatternScreen({super.key, this.reviewWords, this.reviewPair});
  final List<VocabularyWord>? reviewWords;
  final LanguagePair? reviewPair;

  @override
  State<PatternScreen> createState() => _PatternScreenState();
}

class _PatternScreenState extends State<PatternScreen> {
  PatternMode _mode = PatternMode.prefix;
  String _branch = '';
  List<VocabularyWord> _words = [];
  final Map<String, List<VocabularyWord>> _checked = {};
  final TextEditingController _maxController = TextEditingController(text: kIsWeb ? '' : '50');
  final Set<WordDifficulty> _difficultyFilters = {};
  final WordDifficultyService _difficultyService = WordDifficultyService();
  final SavedWordsService _savedService = SavedWordsService();
  bool _all = true;
  bool _loading = true;
  String? _error;
  LanguagePair? _pair;

  @override
  void initState() {
    super.initState();
    _difficultyService.ready.then((_) {
      if (mounted) setState(() {});
    });
    _load();
  }

  Future<void> _load() async {
    try {
      if (widget.reviewWords != null && widget.reviewPair != null) {
        await TopicService().ready;
        if (!mounted) return;
        setState(() {
          _pair = widget.reviewPair;
          _words = PatternEngine.distinct(widget.reviewWords!);
          _loading = false;
        });
        return;
      }
      if (LanguageService().currentLanguagePair == null) {
        await LanguageService().initialize();
      }
      final pair = LanguageService().currentLanguagePair;
      if (pair == null) throw StateError('Select your language pair first.');
      await Future.wait([TopicService().ready, VocabularyService().ready]);
      final topics = QuizSelection.activeTopics(pair.key);
      final words = await PatternCatalog.forPair(
        pair.key, topicIds: topics.map((t) => t.id).toList(),
      );
      if (!mounted) return;
      setState(() { _pair = pair; _words = words; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  @override
  void dispose() {
    _maxController.dispose();
    super.dispose();
  }

  List<VocabularyWord> get _pool {
    if (_branch.isEmpty) return _words;
    return _words.where((w) {
      final key = PatternEngine.lettersOnly(w.sourceWord);
      return _mode == PatternMode.prefix
          ? key.startsWith(_branch) : key.endsWith(_branch);
    }).toList();
  }

  String _groupId(PatternGroup group) => '${_pair?.key}:${_mode.name}:${group.key}';

  bool _matchesDifficulty(VocabularyWord word) =>
      !kIsWeb || _difficultyFilters.isEmpty ||
      _difficultyFilters.contains(_difficultyService.getDifficulty(word));

  List<VocabularyWord> get _selection {
    final filtered = PatternEngine.selectedWords(_checked)
        .where(_matchesDifficulty)
        .toList();
    if (_all) return filtered;
    final maximum = int.tryParse(_maxController.text);
    // An empty maximum means no cap; a positive value limits the quiz.
    if (maximum == null) return filtered;
    if (maximum < 1) return [];
    return filtered.take(maximum).toList();
  }


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


  Widget _difficultyMenu(VocabularyWord word) {
    final difficulty = _difficultyService.getDifficulty(word);
    return PopupMenuButton<String>(
      tooltip: 'Set difficulty',
      icon: Icon(difficulty == null ? Icons.circle_outlined : Icons.circle,
          size: 18, color: _difficultyColor(difficulty)),
      onSelected: (value) {
        final rating = value == 'clear' ? null : WordDifficulty.values.firstWhere(
          (option) => option.name == value,
        );
        _difficultyService.setDifficulty(word, rating);
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


  Widget _difficultyFilterControls() => Wrap(
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
  );

  Future<void> _toggleSavedWord(VocabularyWord word) async {
    final saved = await _savedService.toggleWord(word);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved ? 'Saved to My List' : 'Removed from My List'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openGroup(PatternGroup group) {
    if (_mode == PatternMode.prefix || _mode == PatternMode.suffix) {
      // A terminal group can be selected without adding a redundant drill level.
      if (group.words.every((w) =>
          PatternEngine.lettersOnly(w.sourceWord).runes.length <=
          group.key.runes.length)) return;
      setState(() => _branch = group.key);
    } else {
      setState(() {
        final id = _groupId(group);
        if (_checked.containsKey(id)) { _checked.remove(id); }
        else { _checked[id] = group.words; }
      });
    }
  }

  void _select(PatternGroup group, bool checked) {
    setState(() {
      final id = _groupId(group);
      if (checked) { _checked[id] = group.words; }
      else { _checked.remove(id); }
    });
  }

  List<QuizQuestion> _makeQuiz(List<VocabularyWord> selected) {
    final all = PatternEngine.distinct([..._words, ...selected])
      .where(GrammarPracticeService().isEligible).toList();
    final random = Random();
    final result = <QuizQuestion>[];
    for (final word in selected.where(GrammarPracticeService().isEligible)) {
      final distractors = all
          .map((w) => w.targetWord)
          .where((s) => s != word.targetWord)
          .toSet().toList()..shuffle(random);
      final wrong = distractors.take(3).toList();
      if (wrong.isEmpty) continue;
      final options = [word.targetWord, ...wrong]..shuffle(random);
      result.add(QuizQuestion(
        word: word,
        options: options,
        correctIndex: options.indexOf(word.targetWord),
        wrongAnswers: wrong,
        topic: word.topic,
      ));
    }
    return result..shuffle(random);
  }

  void _startQuiz() {
    final pair = _pair, selected = _selection;
    if (pair == null || selected.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => QuizPage(
        languagePair: pair,
        selectedTopics: TopicService().topics.where((t) =>
            selected.map((w) => w.topic).contains(t.id)).toList(),
        questionCount: selected.length,
        answerOptionCount: 3,
        initialQuestions: _makeQuiz(selected),
      ),
    ));
  }

  void _startMnemonic() {
    final pair = _pair, selected = _selection;
    if (pair == null || selected.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PatternMnemonicPage(
          words: selected.where(GrammarPracticeService().isEligible).toList(),
          pairKey: pair.key),
    ));
  }

  void _startWriting() {
    final pair = _pair, selected = _selection;
    if (pair == null || selected.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PatternWritingPage(
          words: selected.where(GrammarPracticeService().isEligible).toList(),
          pairKey: pair.key),
    ));
  }

  Future<void> _showGroupTable(PatternGroup group) async {
    final sorted = [...group.words]
      ..sort((a, b) => a.sourceWord.compareTo(b.sourceWord));
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.35,
        maxChildSize: 0.95,
        builder: (context, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
          child: Column(children: [
            Row(children: [
              Expanded(child: Text(
                '${group.title} · ${sorted.length} entries',
                style: Theme.of(context).textTheme.titleLarge,
              )),
              TextButton(
                onPressed: () {
                  _select(group, true);
                  Navigator.pop(sheetContext);
                },
                child: const Text('Select table'),
              ),
            ]),
            const SizedBox(height: 10),
            Expanded(child: ListenableBuilder(
              listenable: Listenable.merge([_savedService, _difficultyService]),
              builder: (context, _) => ListView.separated(
                controller: controller,
                itemCount: sorted.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final w = sorted[i];
                  if (kIsWeb) {
                    final saved = _savedService.isSavedWord(w);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(w.sourceWord),
                      subtitle: Text('${w.topic} · ${w.targetWord}',
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: Icon(saved ? Icons.star : Icons.star_border),
                          color: saved ? Colors.amber : Theme.of(context).colorScheme.outline,
                          tooltip: saved ? 'Remove from My List' : 'Save to My List',
                          onPressed: () => _toggleSavedWord(w),
                        ),
                        _difficultyMenu(w),
                      ]),
                    );
                  }
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(w.sourceWord),
                    subtitle: Text(w.topic),
                    trailing: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 150),
                      child: Text(w.targetWord, textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  );
                },
              ),
            )),
          ]),
        ),
      ),
    );
    if (mounted) setState(() {});
  }


  Widget _groupCard(PatternGroup group) {
    final theme = Theme.of(context);
    final checked = _checked.containsKey(_groupId(group));
    final branchable = (_mode == PatternMode.prefix || _mode == PatternMode.suffix) &&
        group.words.any((w) =>
          PatternEngine.lettersOnly(w.sourceWord).runes.length >
          group.key.runes.length);
    final preview = group.words.take(4).map((w) =>
        '${w.sourceWord} → ${w.targetWord}').join(' · ');
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Checkbox(
            key: ValueKey('check_${_groupId(group)}'),
            value: checked,
            onChanged: (v) => _select(group, v ?? false),
            semanticLabel: 'Add ${group.title} to combined quiz',
          ),
          Expanded(
            child: InkWell(
              onTap: () => _showGroupTable(group),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 6, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(group.title, style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Text('(${group.words.length})', style: theme.textTheme.labelMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ]),
                    const SizedBox(height: 4),
                    Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          ),
          if (branchable)
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Explore next letters',
              onPressed: () => _openGroup(group),
            ),
        ],
      ),
    );
  }

  Widget _footer() {
    final theme = Theme.of(context);
    final selected = _selection;
    return Material(
      elevation: 4,
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(child: Text(
                '${_checked.length} groups · ${selected.length} unique questions',
                style: theme.textTheme.labelMedium,
              )),
              TextButton(
                onPressed: _checked.isEmpty ? null : () =>
                    setState(() => _checked.clear()),
                child: const Text('Clear'),
              ),
            ]),
            Row(children: [
              ChoiceChip(label: const Text('All selected'), selected: _all,
                onSelected: (_) => setState(() => _all = true)),
              const SizedBox(width: 8),
              ChoiceChip(label: const Text('Maximum'), selected: !_all,
                onSelected: (_) => setState(() => _all = false)),
              if (!_all) ...[
                const SizedBox(width: 8),
                SizedBox(width: 100, child: TextField(
                  controller: _maxController,
                  decoration: const InputDecoration(
                    isDense: true, labelText: 'Max (optional)', hintText: 'No limit',
                    border: OutlineInputBorder(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                )),
              ],
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: FilledButton.icon(
                onPressed: selected.isEmpty ? null : _startQuiz,
                icon: const Icon(Icons.quiz_outlined),
                label: Text('Quiz (${selected.length})'),
              )),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(
                onPressed: selected.isEmpty ? null : _startWriting,
                child: Text('Write (${selected.length})'),
              )),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(
                onPressed: selected.isEmpty ? null : _startMnemonic,
                child: Text('Mnemonic (${selected.length})'),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rawPool = _pool;
    final pool = kIsWeb && _difficultyFilters.isNotEmpty
        ? rawPool.where((w) => _difficultyFilters.contains(
            _difficultyService.getDifficulty(w))).toList()
        : rawPool;
    final depth = _branch.runes.length + 1;
    final groups = PatternEngine.group(
      pool, _mode, branch: _branch, depth: depth,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Patterns'), centerTitle: true),
      bottomNavigationBar: _footer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    Text(
                      '${_pair!.source.flag} ${_pair!.source.name} → ${_pair!.target.flag} ${_pair!.target.name}',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Text('Words (${_words.length}) · ${QuizSelection.activeTopics(_pair?.key).map((t) => t.name).join(', ')}',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 18),
                    Wrap(spacing: 7, runSpacing: 4, children: [
                      for (final mode in PatternMode.values)
                        ChoiceChip(
                          label: Text(switch(mode) {
                            PatternMode.prefix => 'Starts with',
                            PatternMode.suffix => 'Ends with',
                            PatternMode.letters => 'Letters',
                            PatternMode.words => 'Word count',
                          }),
                          selected: _mode == mode,
                          onSelected: (_) => setState(() {
                            _mode = mode; _branch = '';
                          }),
                        ),
                    ]),
                    if (kIsWeb) ...[
                      const SizedBox(height: 12),
                      Text('Difficulty filters', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 6),
                      _difficultyFilterControls(),
                    ],
                    if (_branch.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Align(alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          icon: const Icon(Icons.arrow_back),
                          label: Text('Back · ${_branch}'),
                          onPressed: () => setState(() {
                            final chars = _branch.runes.toList();
                            chars.removeAt(_mode == PatternMode.prefix
                                ? chars.length - 1 : 0);
                            _branch = String.fromCharCodes(chars);
                          }),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text('Pattern groups (${groups.length})',
                      style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (groups.isEmpty) const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('No vocabulary for this language pair yet.'),
                    ),
                    for (final group in groups) _groupCard(group),
                    if (_pair != null) TextButton(
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const LanguageSetupPage()));
                        setState(() { _loading = true; _checked.clear(); _branch = ''; });
                        await _load();
                      },
                      child: const Text('Change language pair'),
                    ),
                  ],
                ),
    );
  }
}
