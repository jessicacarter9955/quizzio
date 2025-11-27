import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wordweaver/services/language_service.dart';
import 'package:wordweaver/l10n/app_localizations.dart';
import 'package:wordweaver/screens/settings_page.dart';

class ListeningTabPage extends StatefulWidget {
  const ListeningTabPage({super.key});

  @override
  State<ListeningTabPage> createState() => _ListeningTabPageState();
}

class _ListeningTabPageState extends State<ListeningTabPage> {
  final FlutterTts _tts = FlutterTts();
  final LanguageService _languageService = LanguageService();
  final TextEditingController _answerController = TextEditingController();

  final List<_ListeningItem> _items = _demoListeningItems;

  int _currentIndex = 0;
  String? _feedback;
  double? _lastScore;

  @override
  void initState() {
    super.initState();
    _configureTts();
  }

  Future<void> _configureTts() async {
    final pair = _languageService.currentLanguagePair;
    final code = pair?.targetLanguage.code ?? 'it';
    await _tts.setLanguage(code);
    await _tts.awaitSpeakCompletion(true);
  }

  @override
  void dispose() {
    _tts.stop();
    _answerController.dispose();
    super.dispose();
  }

  _ListeningItem get _currentItem => _items[_currentIndex];

  Future<void> _playCurrent() async {
    await _tts.stop();
    final text = _currentItem.targetText;
    if (text.trim().isEmpty) return;
    await _tts.speak(text);
  }

  void _checkAnswer() {
    final typed = _answerController.text.trim();
    if (typed.isEmpty) {
      setState(() {
        _feedback = 'Type what you hear, then tap Check.';
        _lastScore = null;
      });
      return;
    }
    final expected = _currentItem.targetText;
    final score = _similarityScore(expected, typed);
    String message;
    if (score > 0.85) {
      message = 'Excellent!';
    } else if (score > 0.7) {
      message = 'Good, just a few small differences.';
    } else if (score > 0.5) {
      message = 'Almost there, listen again and try to fix the spelling.';
    } else {
      message = 'Quite different. Listen again and focus on each word.';
    }
    setState(() {
      _lastScore = score;
      _feedback = message;
    });
  }

  void _next() {
    if (_currentIndex < _items.length - 1) {
      setState(() {
        _currentIndex++;
        _answerController.clear();
        _feedback = null;
        _lastScore = null;
      });
    }
  }

  double _similarityScore(String expected, String actual) {
    final a = _normalize(expected);
    final b = _normalize(actual);
    if (a.isEmpty || b.isEmpty) return 0;
    final distance = _levenshtein(a, b);
    final maxLen = a.length > b.length ? a.length : b.length;
    return 1 - distance / maxLen;
  }

  String _normalize(String input) {
    final lower = input.toLowerCase();
    final onlyLetters = lower.replaceAll(RegExp(r"[^a-zàèéìòùáíóúüçñ ]"), '');
    return onlyLetters.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  int _levenshtein(String a, String b) {
    final m = a.length;
    final n = b.length;
    if (m == 0) return n;
    if (n == 0) return m;
    final dp = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));
    for (var i = 0; i <= m; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j <= n; j++) {
      dp[0][j] = j;
    }
    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        final deletion = dp[i - 1][j] + 1;
        final insertion = dp[i][j - 1] + 1;
        final substitution = dp[i - 1][j - 1] + cost;
        var value = deletion;
        if (insertion < value) value = insertion;
        if (substitution < value) value = substitution;
        dp[i][j] = value;
      }
    }
    return dp[m][n];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final item = _currentItem;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.navListening,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Exercise ${_currentIndex + 1} of ${_items.length}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tap play to hear the sentence in ${item.languageLabel}. Then type exactly what you hear.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: _playCurrent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.prompt,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _answerController,
                decoration: const InputDecoration(
                  labelText: 'Type what you hear',
                  border: OutlineInputBorder(),
                ),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _checkAnswer,
                      child: const Text('Check'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _currentIndex < _items.length - 1
                          ? _next
                          : null,
                      child: const Text('Next'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_feedback != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _feedback!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      if (_lastScore != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Similarity: ${(100 * _lastScore!).round()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.8),
                          ),
                        ),
                      ],
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

class _ListeningItem {
  final String id;
  final String prompt; // what we show (usually English)
  final String targetText; // what is spoken & expected (usually Italian)
  final String languageLabel;

  const _ListeningItem({
    required this.id,
    required this.prompt,
    required this.targetText,
    required this.languageLabel,
  });
}

final List<_ListeningItem> _demoListeningItems = [
  _ListeningItem(
    id: 'l1',
    prompt: 'How do you say: It\'s a rainy Sunday afternoon in Rome?',
    targetText: 'È una piovosa domenica pomeriggio a Roma.',
    languageLabel: 'Italian',
  ),
  _ListeningItem(
    id: 'l2',
    prompt: 'How do you say: Grandma Clara calls him from the kitchen?',
    targetText: 'La nonna Clara lo chiama dalla cucina.',
    languageLabel: 'Italian',
  ),
  _ListeningItem(
    id: 'l3',
    prompt:
        'How do you say: On the table there are carrots, potatoes and fresh basil?',
    targetText: 'Sul tavolo ci sono carote, patate e basilico fresco.',
    languageLabel: 'Italian',
  ),
];
