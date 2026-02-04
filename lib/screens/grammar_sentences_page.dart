import 'package:flutter/material.dart';
import 'package:wordweaver/models/language_pair.dart';
import 'package:wordweaver/services/grammar_service.dart';

class GrammarSentencesPage extends StatefulWidget {
  final LanguagePair languagePair;

  const GrammarSentencesPage({super.key, required this.languagePair});

  @override
  State<GrammarSentencesPage> createState() => _GrammarSentencesPageState();
}

enum _GrammarViewMode { wheels, card, list }

class _GrammarSentencesPageState extends State<GrammarSentencesPage> {
  final GrammarService _grammarService = GrammarService();
  bool _loading = true;
  String? _error;
  List<GrammarSentence> _sentences = [];
  int _currentIndex = 0;
  String? _sourceLanguageName;
  String? _targetLanguageName;
  List<GrammarWheelColumn> _columns = [];
  List<FixedExtentScrollController> _wheelControllers = [];
  int _comboIndex = 0;
  _GrammarViewMode _viewMode = _GrammarViewMode.wheels;
  final List<GrammarSentence> _savedSentences = [];

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
      if (!mounted) return;
      setState(() {
        _columns = wheelColumns;
        _wheelControllers = List<FixedExtentScrollController>.generate(
          wheelColumns.length,
          (_) => FixedExtentScrollController(),
        );
        _comboIndex = 0;
        _sentences = sentences;
        _currentIndex = 0;
        _sourceLanguageName =
            display?['sourceLanguage'] ??
            widget.languagePair.sourceLanguage.name;
        _targetLanguageName =
            display?['targetLanguage'] ??
            widget.languagePair.targetLanguage.name;
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
      appBar: AppBar(title: const Text('Grammar sentences')),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Language pair',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_sourceLanguageName ?? ''} → ${_targetLanguageName ?? ''} ($pairKey)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Generated sentence rotations from grammar_profiles_mock.json',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
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

  Widget _buildWheelsBody(ThemeData theme) {
    if (_columns.isEmpty) {
      return Center(
        child: Text(
          'No wheel data available for this language pair.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    final columns = _columns;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Row(
            children: List.generate(columns.length, (index) {
              final column = columns[index];
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
                        itemExtent: 32,
                        onSelectedItemChanged: (selected) {
                          setState(() {
                            _comboIndex = selected;
                          });
                          for (var i = 0; i < _wheelControllers.length; i++) {
                            if (i == index) continue;
                            final len = columns[i].entries.length;
                            if (len == 0) continue;
                            final targetIndex = _comboIndex % len;
                            final c = _wheelControllers[i];
                            if (c.hasClients) {
                              c.animateToItem(
                                targetIndex,
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.easeOut,
                              );
                            }
                          }
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          builder: (context, itemIndex) {
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
                          childCount: column.entries.length,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        _buildWheelSentencePreview(theme),
        const SizedBox(height: 8),
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
              const SizedBox(width: 12),
              if (_savedSentences.isNotEmpty)
                Text(
                  '${_savedSentences.length} saved',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_savedSentences.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'Saved sentences',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                _buildSavedList(theme),
                const Divider(height: 1),
              ],
              Expanded(child: _buildListBody(theme)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWheelSentencePreview(ThemeData theme) {
    final sentence = _currentWheelSentence;
    if (sentence == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            sentence.targetSentence,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sentence.sourceSentence,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  GrammarSentence? get _currentWheelSentence {
    if (_columns.isEmpty) return null;
    final sourceParts = <String>[];
    final targetParts = <String>[];
    for (var i = 0; i < _columns.length; i++) {
      final column = _columns[i];
      if (column.entries.isEmpty) continue;
      final index = _comboIndex % column.entries.length;
      final entry = column.entries[index];
      sourceParts.add(entry.source);
      targetParts.add(entry.target);
    }
    if (sourceParts.isEmpty || targetParts.isEmpty) return null;
    return GrammarSentence(
      sourceSentence: sourceParts.join(' '),
      targetSentence: targetParts.join(' '),
      indices: List<int>.generate(
        _columns.length,
        (i) => _comboIndex % _columns[i].entries.length,
      ),
    );
  }

  void _saveCurrentSentence() {
    final sentence = _currentWheelSentence;
    if (sentence == null) return;
    final exists = _savedSentences.any(
      (s) =>
          s.sourceSentence == sentence.sourceSentence &&
          s.targetSentence == sentence.targetSentence,
    );
    if (exists) return;
    setState(() {
      _savedSentences.add(sentence);
    });
  }

  void _syncWheelsToSentence(GrammarSentence sentence) {
    final indices = sentence.indices;
    if (indices == null || indices.isEmpty) return;
    _comboIndex = indices[0];
    for (var i = 0; i < _wheelControllers.length && i < indices.length; i++) {
      final controller = _wheelControllers[i];
      final column = _columns[i];
      if (column.entries.isEmpty) continue;
      final targetIndex = indices[i].clamp(0, column.entries.length - 1);
      if (controller.hasClients) {
        controller.animateToItem(
          targetIndex,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    }
    setState(() {});
  }

  Widget _buildSavedList(ThemeData theme) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _savedSentences.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final sentence = _savedSentences[index];
        return ListTile(
          leading: Icon(Icons.bookmark, color: theme.colorScheme.primary),
          title: Text(
            sentence.targetSentence,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            sentence.sourceSentence,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              setState(() {
                _savedSentences.removeAt(index);
              });
            },
          ),
          onTap: () {
            final listIndex = _sentences.indexWhere(
              (s) =>
                  s.sourceSentence == sentence.sourceSentence &&
                  s.targetSentence == sentence.targetSentence,
            );
            setState(() {
              if (listIndex != -1) {
                _currentIndex = listIndex;
              }
            });
            if (_viewMode == _GrammarViewMode.wheels) {
              _syncWheelsToSentence(sentence);
            }
          },
        );
      },
    );
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
