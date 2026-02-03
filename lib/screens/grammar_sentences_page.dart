import 'package:flutter/material.dart';
import 'package:wordweaver/models/language_pair.dart';
import 'package:wordweaver/services/grammar_service.dart';

class GrammarSentencesPage extends StatefulWidget {
  final LanguagePair languagePair;

  const GrammarSentencesPage({super.key, required this.languagePair});

  @override
  State<GrammarSentencesPage> createState() => _GrammarSentencesPageState();
}

class _GrammarSentencesPageState extends State<GrammarSentencesPage> {
  final GrammarService _grammarService = GrammarService();
  bool _loading = true;
  String? _error;
  List<GrammarSentence> _sentences = [];
  int _currentIndex = 0;
  String? _sourceLanguageName;
  String? _targetLanguageName;

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
      final sentences = await _grammarService.generateSentencesForPair(
        key,
        maxSentences: 200,
      );
      if (!mounted) return;
      setState(() {
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
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
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
                Expanded(
                  child: ListView.separated(
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
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
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
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.7,
                                  )
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                          ),
                        ),
                        dense: true,
                        onTap: () {
                          setState(() {
                            _currentIndex = index;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
