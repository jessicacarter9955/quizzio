import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wordweaver/l10n/app_localizations.dart';
import 'package:wordweaver/services/language_service.dart';
import 'package:wordweaver/services/speech_service.dart';

class ReadingTabPage extends StatelessWidget {
  const ReadingTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final stories = _demoStories;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.navReading,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: stories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final story = stories[index];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoryReadingPage(story: story),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    story.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.08,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          story.level,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${story.estimatedMinutes} min',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        story.topic,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class StoryReadingPage extends StatefulWidget {
  final _Story story;

  const StoryReadingPage({super.key, required this.story});

  @override
  State<StoryReadingPage> createState() => _StoryReadingPageState();
}

class _StoryReadingPageState extends State<StoryReadingPage> {
  final FlutterTts _tts = FlutterTts();
  final SpeechService _speechService = SpeechService();
  final LanguageService _languageService = LanguageService();

  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isPronunciationListening = false;
  double? _lastPronunciationScore;

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
    super.dispose();
  }

  _StorySentence get _currentSentence => widget.story.sentences[_currentIndex];

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      setState(() {
        _isPlaying = false;
      });
      await _tts.stop();
      return;
    }
    _playFromCurrent();
  }

  Future<void> _playFromCurrent() async {
    setState(() {
      _isPlaying = true;
    });
    await _tts.stop();
    for (var i = _currentIndex; i < widget.story.sentences.length; i++) {
      if (!_isPlaying) break;
      setState(() {
        _currentIndex = i;
      });
      final text = widget.story.sentences[i].targetText;
      if (text.trim().isEmpty) continue;
      await _tts.speak(text);
    }
    if (!mounted) return;
    setState(() {
      _isPlaying = false;
    });
  }

  Future<void> _goTo(int index, {bool speak = false}) async {
    if (index < 0 || index >= widget.story.sentences.length) return;
    setState(() {
      _currentIndex = index;
    });
    if (speak) {
      await _tts.stop();
      final text = _currentSentence.targetText;
      if (text.trim().isNotEmpty) {
        await _tts.speak(text);
      }
    }
  }

  Future<void> _startPronunciationPractice() async {
    if (_isPronunciationListening) {
      await _speechService.stop();
      setState(() {
        _isPronunciationListening = false;
      });
      return;
    }

    final pair = _languageService.currentLanguagePair;
    final localeId = pair?.targetLanguage.code;

    final available = await _speechService.ensureInitialized();
    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Speech recognition not available'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isPronunciationListening = true;
    });

    await _speechService.listen(
      localeId: localeId,
      onResult: (text, isFinal) {
        if (!isFinal || !mounted) return;
        final cleaned = text.trim();
        setState(() {
          _isPronunciationListening = false;
        });
        if (cleaned.isEmpty) return;
        final target = _currentSentence.targetText;
        final score = _similarityScore(target, cleaned);
        setState(() {
          _lastPronunciationScore = score;
        });
      },
    );
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

  int _scoreToStars(double? score) {
    if (score == null) return 0;
    if (score < 0.3) return 1;
    if (score < 0.5) return 2;
    if (score < 0.7) return 3;
    if (score < 0.85) return 4;
    return 5;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final story = widget.story;
    final current = _currentSentence;
    final stars = _scoreToStars(_lastPronunciationScore);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          story.title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_currentIndex + 1}/${story.sentences.length}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                if (_lastPronunciationScore != null)
                  Text(
                    'Score: ${(100 * _lastPronunciationScore!).round()}%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: story.sentences.length,
              itemBuilder: (context, index) {
                final sentence = story.sentences[index];
                final isActive = index == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.6,
                          )
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          sentence.sourceText,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          sentence.targetText,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        onPressed: _currentIndex > 0
                            ? () => _goTo(_currentIndex - 1, speak: true)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause_circle : Icons.play_circle,
                          size: 32,
                        ),
                        onPressed: _togglePlay,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        onPressed: _currentIndex < story.sentences.length - 1
                            ? () => _goTo(_currentIndex + 1, speak: true)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (var i = 0; i < 5; i++)
                        Icon(
                          i < stars ? Icons.star : Icons.star_border,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pronunciation rating for current sentence',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _startPronunciationPractice,
                    icon: Icon(
                      _isPronunciationListening ? Icons.mic_off : Icons.mic,
                    ),
                    label: Text(
                      _isPronunciationListening
                          ? 'Listening... tap to stop'
                          : 'Practice speaking this sentence',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    current.targetText,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StorySentence {
  final String id;
  final String sourceText;
  final String targetText;

  const _StorySentence({
    required this.id,
    required this.sourceText,
    required this.targetText,
  });
}

class _Story {
  final String id;
  final String title;
  final String description;
  final String level;
  final int estimatedMinutes;
  final String topic;
  final List<_StorySentence> sentences;

  const _Story({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.estimatedMinutes,
    required this.topic,
    required this.sentences,
  });
}

final List<_Story> _demoStories = [
  _Story(
    id: 'grandma_soup',
    title: 'Nonna Clara\'s Magic Soup',
    description:
        'A short story about an Italian grandma who teaches her grandson new words while cooking soup.',
    level: 'A1–A2',
    estimatedMinutes: 3,
    topic: 'Food & Drink, Family & Relationships',
    sentences: [
      _StorySentence(
        id: 's1',
        sourceText: 'It\'s a rainy Sunday afternoon in Rome.',
        targetText: 'È una piovosa domenica pomeriggio a Roma.',
      ),
      _StorySentence(
        id: 's2',
        sourceText: 'Luca is bored and scrolling on his phone.',
        targetText: 'Luca è annoiato e scorre sul suo telefono.',
      ),
      _StorySentence(
        id: 's3',
        sourceText: 'Grandma Clara calls him from the kitchen.',
        targetText: 'La nonna Clara lo chiama dalla cucina.',
      ),
      _StorySentence(
        id: 's4',
        sourceText: '"Come here, little professor, let\'s cook a magic soup!"',
        targetText:
            '"Vieni qui, piccolo professore, cuciniamo una zuppa magica!"',
      ),
      _StorySentence(
        id: 's5',
        sourceText: 'On the table there are carrots, potatoes and fresh basil.',
        targetText: 'Sul tavolo ci sono carote, patate e basilico fresco.',
      ),
      _StorySentence(
        id: 's6',
        sourceText: '"Repeat after me," says Grandma. "Carrot is carota."',
        targetText: '"Ripeti dopo di me," dice la nonna. "Carota è carota."',
      ),
      _StorySentence(
        id: 's7',
        sourceText:
            'Luca laughs and says the word with an exaggerated rolling R.',
        targetText:
            'Luca ride e dice la parola con una R esageratamente arrotata.',
      ),
      _StorySentence(
        id: 's8',
        sourceText:
            'For every ingredient, Grandma teaches him a new Italian word.',
        targetText:
            'Per ogni ingrediente, la nonna gli insegna una nuova parola in italiano.',
      ),
      _StorySentence(
        id: 's9',
        sourceText:
            'When the soup is ready, the whole kitchen smells like basil and comfort.',
        targetText:
            'Quando la zuppa è pronta, tutta la cucina profuma di basilico e conforto.',
      ),
      _StorySentence(
        id: 's10',
        sourceText:
            'Luca tastes a spoonful and smiles: he has learned new words and a new recipe.',
        targetText:
            'Luca assaggia un cucchiaio e sorride: ha imparato nuove parole e una nuova ricetta.',
      ),
    ],
  ),
  _Story(
    id: 'school_bus',
    title: 'First Day on the School Bus',
    description:
        'A nervous student discovers friendly classmates and learns school vocabulary on the bus.',
    level: 'A1–A2',
    estimatedMinutes: 4,
    topic: 'School, Transportation',
    sentences: [
      _StorySentence(
        id: 'sb1',
        sourceText: 'It is Marco\'s first day at a new school.',
        targetText: 'È il primo giorno di scuola nuova per Marco.',
      ),
      _StorySentence(
        id: 'sb2',
        sourceText:
            'He waits at the bus stop with his heavy backpack and a small lunch box.',
        targetText:
            'Aspetta alla fermata dell\'autobus con lo zaino pesante e una piccola lunch box.',
      ),
      _StorySentence(
        id: 'sb3',
        sourceText:
            'A yellow bus arrives and the driver smiles at him in the mirror.',
        targetText:
            'Arriva un autobus giallo e l\'autista gli sorride dallo specchio.',
      ),
      _StorySentence(
        id: 'sb4',
        sourceText:
            'Two classmates invite him to sit next to them and ask his name.',
        targetText:
            'Due compagni lo invitano a sedersi accanto a loro e gli chiedono il nome.',
      ),
      _StorySentence(
        id: 'sb5',
        sourceText:
            'On the way, they point out the gym, the library and the big school yard.',
        targetText:
            'Durante il tragitto indicano la palestra, la biblioteca e il grande cortile della scuola.',
      ),
      _StorySentence(
        id: 'sb6',
        sourceText:
            'When Marco gets off the bus, he feels lighter: he already has two new friends.',
        targetText:
            'Quando Marco scende dall\'autobus si sente più leggero: ha già due nuovi amici.',
      ),
    ],
  ),
  _Story(
    id: 'office_break',
    title: 'Coffee Break at the Office',
    description:
        'Colleagues share a quick coffee break and talk about projects, stress and small joys at work.',
    level: 'A2–B1',
    estimatedMinutes: 4,
    topic: 'Work, Emotions & Senses',
    sentences: [
      _StorySentence(
        id: 'ob1',
        sourceText:
            'Sara closes her laptop and walks to the small office kitchen.',
        targetText:
            'Sara chiude il portatile e va verso la piccola cucina dell\'ufficio.',
      ),
      _StorySentence(
        id: 'ob2',
        sourceText:
            'The smell of fresh coffee mixes with the sound of the printer.',
        targetText:
            'L\'odore di caffè appena fatto si mescola al rumore della stampante.',
      ),
      _StorySentence(
        id: 'ob3',
        sourceText:
            'Her colleague Ahmed complains about a long meeting full of numbers.',
        targetText:
            'Il collega Ahmed si lamenta di una lunga riunione piena di numeri.',
      ),
      _StorySentence(
        id: 'ob4',
        sourceText:
            'They laugh, take a deep breath and decide to plan a quiet lunch outside.',
        targetText:
            'Ridono, fanno un respiro profondo e decidono di organizzare un pranzo tranquillo fuori.',
      ),
      _StorySentence(
        id: 'ob5',
        sourceText:
            'For a few minutes, the office feels less like a battlefield and more like a team.',
        targetText:
            'Per qualche minuto l\'ufficio sembra meno un campo di battaglia e più una squadra.',
      ),
    ],
  ),
  _Story(
    id: 'evening_match',
    title: 'Evening Match in the Park',
    description:
        'Friends meet after work to play football in the park and forget about their phones.',
    level: 'A2',
    estimatedMinutes: 3,
    topic: 'Sports, Hobbies & Leisure',
    sentences: [
      _StorySentence(
        id: 'em1',
        sourceText:
            'The sun is going down when a group of friends arrives at the small football field.',
        targetText:
            'Il sole sta tramontando quando un gruppo di amici arriva al piccolo campo da calcio.',
      ),
      _StorySentence(
        id: 'em2',
        sourceText:
            'They leave their bags and phones on a bench and start to warm up.',
        targetText:
            'Lasciamo le borse e i telefoni su una panchina e iniziano a riscaldarsi.',
      ),
      _StorySentence(
        id: 'em3',
        sourceText:
            'Giulia runs fast on the left side and passes the ball to her brother.',
        targetText:
            'Giulia corre veloce sulla sinistra e passa la palla a suo fratello.',
      ),
      _StorySentence(
        id: 'em4',
        sourceText:
            'He shoots, the ball hits the post and everyone shouts with excitement.',
        targetText:
            'Tira, la palla colpisce il palo e tutti gridano per l\'emozione.',
      ),
      _StorySentence(
        id: 'em5',
        sourceText:
            'After the match they sit on the grass, tired but happy, and talk about the best goal.',
        targetText:
            'Dopo la partita si siedono sull\'erba, stanchi ma felici, e parlano del gol più bello.',
      ),
    ],
  ),
];
