import 'package:flutter/material.dart';
import 'package:wordweaver/models/language_pair.dart';
import 'package:wordweaver/screens/language_setup_page.dart';
import 'package:wordweaver/screens/my_list_page.dart';
import 'package:wordweaver/services/grammar_service.dart';
import 'package:wordweaver/services/saved_words_service.dart';
import 'package:wordweaver/services/verb_conjugation_service.dart';

class GrammarSentencesPage extends StatefulWidget {
  final LanguagePair languagePair;

  const GrammarSentencesPage({super.key, required this.languagePair});

  @override
  State<GrammarSentencesPage> createState() => _GrammarSentencesPageState();
}

enum _GrammarViewMode { wheels, card, list }

class _GrammarSentencesPageState extends State<GrammarSentencesPage> {
  final GrammarService _grammarService = GrammarService();
  final VerbConjugationService _verbService = VerbConjugationService();
  final SavedWordsService _savedWordsService = SavedWordsService();
  bool _loading = true;
  String? _error;
  List<GrammarSentence> _sentences = [];
  int _currentIndex = 0;
  String? _sourceLanguageName;
  String? _targetLanguageName;
  List<GrammarWheelColumn> _columns = [];
  List<FixedExtentScrollController> _wheelControllers = [];
  List<int> _wheelIndices = [];
  _GrammarViewMode _viewMode = _GrammarViewMode.wheels;
  List<String> _tenseIds = [];
  Map<String, String> _tenseNames = {};
  List<String> _verbKeys = [];
  String? _selectedTenseId;
  String? _selectedVerbKey;
  List<ConjugationEntry> _conjugations = [];
  int _conjugationIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _grammarService.ensureLoaded();
      final key = widget.languagePair.key;
      final display = _grammarService.getLanguagePairDisplay(key);
      final wheelColumns = await _grammarService.generateWheelColumnsForPair(
        key,
      );
      final sentences = await _grammarService.generateSentencesForPair(
        key,
        maxSentences: 200,
      );

      await _verbService.ensureLoaded();
      final tenseIds = _verbService.getAvailableTenses(key);
      final tenseNames = <String, String>{};
      for (final id in tenseIds) {
        final name = _verbService.getTenseDisplayName(key, id) ?? id;
        tenseNames[id] = name;
      }
      String? selectedTenseId;
      if (tenseIds.isNotEmpty) {
        selectedTenseId = tenseIds.first;
      }
      List<String> verbKeys = [];
      String? selectedVerbKey;
      List<ConjugationEntry> conjugations = [];
      if (selectedTenseId != null) {
        verbKeys = _verbService.getAvailableVerbs(key, selectedTenseId);
        if (verbKeys.isNotEmpty) {
          selectedVerbKey = verbKeys.first;
          conjugations = _verbService.getConjugations(
            key,
            selectedTenseId,
            selectedVerbKey,
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _columns = wheelColumns;
        _wheelControllers = List<FixedExtentScrollController>.generate(
          wheelColumns.length,
          (_) => FixedExtentScrollController(),
        );
        _wheelIndices = List<int>.filled(wheelColumns.length, 0);
        _sentences = sentences;
        _currentIndex = 0;
        _sourceLanguageName =
            display?['sourceLanguage'] ??
            widget.languagePair.sourceLanguage.name;
        _targetLanguageName =
            display?['targetLanguage'] ??
            widget.languagePair.targetLanguage.name;
        _tenseIds = tenseIds;
        _tenseNames = tenseNames;
        _verbKeys = verbKeys;
        _selectedTenseId = selectedTenseId;
        _selectedVerbKey = selectedVerbKey;
        _conjugations = conjugations;
        _conjugationIndex = 0;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _wheelControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pairKey = widget.languagePair.key;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Grammar sentences'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : _sentences.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No sentences available for $pairKey.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLanguagePairPill(theme),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyListPage(),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.bookmark_border,
                          color: theme.colorScheme.onSurface,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildViewModeButton(
                          theme: theme,
                          mode: _GrammarViewMode.wheels,
                          icon: Icons.view_week_outlined,
                          tooltip: 'Wheel view',
                        ),
                        _buildViewModeButton(
                          theme: theme,
                          mode: _GrammarViewMode.card,
                          icon: Icons.view_carousel_outlined,
                          tooltip: 'Card view',
                        ),
                        _buildViewModeButton(
                          theme: theme,
                          mode: _GrammarViewMode.list,
                          icon: Icons.view_list_outlined,
                          tooltip: 'List view',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(child: _buildModeBody(theme)),
              ],
            ),
    );
  }

  Widget _buildModeBody(ThemeData theme) {
    switch (_viewMode) {
      case _GrammarViewMode.wheels:
        return _buildWheelsBody(theme);
      case _GrammarViewMode.card:
        return _buildCardBody(theme);
      case _GrammarViewMode.list:
        return _buildListBody(theme);
    }
  }

  Widget _buildViewModeButton({
    required ThemeData theme,
    required _GrammarViewMode mode,
    required IconData icon,
    required String tooltip,
  }) {
    final isSelected = _viewMode == mode;
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.iconTheme.color?.withValues(alpha: 0.7),
      ),
      onPressed: () {
        if (_viewMode != mode) {
          setState(() {
            _viewMode = mode;
          });
        }
      },
      tooltip: tooltip,
    );
  }

  Widget _buildLanguagePairPill(ThemeData theme) {
    final pair = widget.languagePair;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LanguageSetupPage()),
          );
        },
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                pair.sourceLanguage.flag,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward,
                size: 18,
                color: theme.colorScheme.onPrimaryContainer.withValues(
                  alpha: 0.7,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                pair.targetLanguage.flag,
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWheelsBody(ThemeData theme) {
    if (_tenseIds.isEmpty || _verbKeys.isEmpty || _conjugations.isEmpty) {
      return Center(
        child: Text(
          'No conjugation data available for this language pair.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    final selectedTenseId = _selectedTenseId;
    final selectedVerbKey = _selectedVerbKey;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedTenseId,
                  isDense: true,
                  decoration: InputDecoration(
                    labelText: 'Tense',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  style: theme.textTheme.bodyMedium,
                  items: _tenseIds
                      .map(
                        (id) => DropdownMenuItem<String>(
                          value: id,
                          child: Text(_tenseNames[id] ?? id),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    _onTenseChanged(value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedVerbKey,
                  isDense: true,
                  decoration: InputDecoration(
                    labelText: 'Verb',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  style: theme.textTheme.bodyMedium,
                  items: _verbKeys
                      .map(
                        (v) =>
                            DropdownMenuItem<String>(value: v, child: Text(v)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    _onVerbChanged(value);
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SizedBox(
              height: 260,
              child: Row(
                children: List.generate(_columns.length, (index) {
                  final column = _columns[index];
                  final controller = _wheelControllers[index];
                  return Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            column.name,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            controller: controller,
                            physics: const FixedExtentScrollPhysics(),
                            itemExtent: 40,
                            onSelectedItemChanged: (selected) {
                              if (column.id == 'subject' ||
                                  column.id == 'verb') {
                                setState(() {
                                  if (selected < 0 ||
                                      selected >= _conjugations.length) {
                                    _conjugationIndex = 0;
                                  } else {
                                    _conjugationIndex = selected;
                                  }
                                });
                                // Keep subject and verb aligned
                                for (
                                  var i = 0;
                                  i < _columns.length &&
                                      i < _wheelControllers.length;
                                  i++
                                ) {
                                  if (_columns[i].id != 'subject' &&
                                      _columns[i].id != 'verb') {
                                    continue;
                                  }
                                  final c = _wheelControllers[i];
                                  if (c.hasClients) {
                                    c.animateToItem(
                                      _conjugationIndex,
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                }
                              } else {
                                setState(() {
                                  if (_wheelIndices.length != _columns.length) {
                                    _wheelIndices = List<int>.filled(
                                      _columns.length,
                                      0,
                                    );
                                  }
                                  _wheelIndices[index] = selected;
                                });
                              }
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              builder: (context, itemIndex) {
                                if (column.id == 'subject' ||
                                    column.id == 'verb') {
                                  if (itemIndex < 0 ||
                                      itemIndex >= _conjugations.length) {
                                    return null;
                                  }
                                  final entry = _conjugations[itemIndex];
                                  final text = column.id == 'subject'
                                      ? entry.subjectTarget
                                      : entry.verbTarget;
                                  return Center(
                                    child: Text(
                                      text,
                                      style: theme.textTheme.bodyMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }

                                if (itemIndex < 0 ||
                                    itemIndex >= column.entries.length) {
                                  return null;
                                }
                                final entry = column.entries[itemIndex];
                                return Center(
                                  child: Text(
                                    entry.target,
                                    style: theme.textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              },
                              childCount:
                                  column.id == 'subject' || column.id == 'verb'
                                  ? _conjugations.length
                                  : column.entries.length,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: _currentWheelSentence == null
                    ? null
                    : _saveCurrentSentence,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Save sentence'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  GrammarSentence? get _currentWheelSentence {
    if (_conjugations.isEmpty) return null;
    if (_conjugationIndex < 0 || _conjugationIndex >= _conjugations.length) {
      return null;
    }
    final entry = _conjugations[_conjugationIndex];
    final sourceSentence = '${entry.subjectSource} ${entry.verbSource}';
    final targetSentence = '${entry.subjectTarget} ${entry.verbTarget}';
    return GrammarSentence(
      sourceSentence: sourceSentence,
      targetSentence: targetSentence,
      indices: [_conjugationIndex],
    );
  }

  void _saveCurrentSentence() {
    final sentence = _currentWheelSentence;
    if (sentence == null) return;
    _savedWordsService.addWord(
      sourceWord: sentence.sourceSentence,
      targetWord: sentence.targetSentence,
      languagePairKey: widget.languagePair.key,
      topic: 'grammar_sentence',
    );
  }

  void _syncWheelsToSentence(GrammarSentence sentence) {
    if (_conjugations.isEmpty) return;
    final targetSource = sentence.sourceSentence.trim();
    final targetTarget = sentence.targetSentence.trim();
    final matchIndex = _conjugations.indexWhere((entry) {
      final s = '${entry.subjectSource} ${entry.verbSource}'.trim();
      final t = '${entry.subjectTarget} ${entry.verbTarget}'.trim();
      return s == targetSource && t == targetTarget;
    });
    if (matchIndex == -1) {
      return;
    }
    setState(() {
      _conjugationIndex = matchIndex;
    });
    for (var i = 0; i < _columns.length && i < _wheelControllers.length; i++) {
      if (_columns[i].id != 'subject' && _columns[i].id != 'verb') {
        continue;
      }
      final c = _wheelControllers[i];
      if (c.hasClients) {
        c.animateToItem(
          _conjugationIndex,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _onTenseChanged(String tenseId) {
    final key = widget.languagePair.key;
    final verbs = _verbService.getAvailableVerbs(key, tenseId);
    String? verbKey;
    List<ConjugationEntry> conjugations = [];
    if (verbs.isNotEmpty) {
      verbKey = verbs.first;
      conjugations = _verbService.getConjugations(key, tenseId, verbKey);
    }
    setState(() {
      _selectedTenseId = tenseId;
      _verbKeys = verbs;
      _selectedVerbKey = verbKey;
      _conjugations = conjugations;
      _conjugationIndex = 0;
      // Reset subject/verb wheels to first person
      for (
        var i = 0;
        i < _columns.length && i < _wheelControllers.length;
        i++
      ) {
        if (_columns[i].id != 'subject' && _columns[i].id != 'verb') {
          continue;
        }
        final c = _wheelControllers[i];
        if (c.hasClients) {
          c.jumpToItem(0);
        }
      }
    });
  }

  void _onVerbChanged(String verbKey) {
    final key = widget.languagePair.key;
    final tenseId = _selectedTenseId;
    if (tenseId == null) return;
    final conjugations = _verbService.getConjugations(key, tenseId, verbKey);
    setState(() {
      _selectedVerbKey = verbKey;
      _conjugations = conjugations;
      _conjugationIndex = 0;
      for (
        var i = 0;
        i < _columns.length && i < _wheelControllers.length;
        i++
      ) {
        if (_columns[i].id != 'subject' && _columns[i].id != 'verb') {
          continue;
        }
        final c = _wheelControllers[i];
        if (c.hasClients) {
          c.jumpToItem(0);
        }
      }
    });
  }

  Widget _buildCardBody(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sentence ${_currentIndex + 1} of ${_sentences.length}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _sentences[_currentIndex].targetSentence,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _sentences[_currentIndex].sourceSentence,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _currentIndex > 0
                            ? () {
                                setState(() {
                                  _currentIndex--;
                                });
                              }
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: _currentIndex < _sentences.length - 1
                            ? () {
                                setState(() {
                                  _currentIndex++;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildListBody(theme)),
      ],
    );
  }

  Widget _buildListBody(ThemeData theme) {
    return ListView.separated(
      itemCount: _sentences.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final sentence = _sentences[index];
        final isActive = index == _currentIndex;
        return ListTile(
          leading: Text(
            '${index + 1}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isActive ? FontWeight.w600 : null,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          title: Text(
            sentence.targetSentence,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: isActive ? theme.colorScheme.primary : null,
            ),
          ),
          subtitle: Text(
            sentence.sourceSentence,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isActive
                  ? theme.colorScheme.primary.withValues(alpha: 0.7)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          dense: true,
          onTap: () {
            final sentence = _sentences[index];
            setState(() {
              _currentIndex = index;
            });
            if (_viewMode == _GrammarViewMode.wheels) {
              _syncWheelsToSentence(sentence);
            }
          },
        );
      },
    );
  }
}
