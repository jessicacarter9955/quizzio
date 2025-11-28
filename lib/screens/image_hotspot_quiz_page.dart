import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wordweaver/services/language_service.dart';

class ImageHotspotQuizPage extends StatefulWidget {
  const ImageHotspotQuizPage({super.key});

  @override
  State<ImageHotspotQuizPage> createState() => _ImageHotspotQuizPageState();
}

class _ImageHotspotQuizPageState extends State<ImageHotspotQuizPage> {
  final FlutterTts _tts = FlutterTts();
  final LanguageService _languageService = LanguageService();

  final List<_Hotspot> _hotspots = const [
    _Hotspot(id: 1, x: 0.28, y: 0.28, word: 'lamp'),
    _Hotspot(id: 2, x: 0.72, y: 0.22, word: 'frame'),
    _Hotspot(id: 3, x: 0.32, y: 0.65, word: 'armchair'),
    _Hotspot(id: 4, x: 0.75, y: 0.68, word: 'table'),
  ];

  final Map<int, TextEditingController> _controllers = {};
  int? _activeId;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    for (final h in _hotspots) {
      _controllers[h.id] = TextEditingController();
    }
    _configureTts();
  }

  Future<void> _configureTts() async {
    final pair = _languageService.currentLanguagePair;
    final code = pair?.targetLanguage.code ?? 'es';
    await _tts.setLanguage(code);
    await _tts.awaitSpeakCompletion(true);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _tts.stop();
    super.dispose();
  }

  void _onHotspotTap(int id) {
    setState(() {
      _activeId = _activeId == id ? null : id;
    });
  }

  Future<void> _speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _tts.stop();
    await _tts.speak(trimmed);
  }

  void _checkAnswers() {
    setState(() {
      _checked = true;
    });
  }

  bool _isCorrect(_Hotspot h) {
    final controller = _controllers[h.id];
    final value = controller?.text.trim().toLowerCase() ?? '';
    return value.isNotEmpty && value == h.word.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Image hotspots',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight;

                    _Hotspot? active;
                    if (_activeId != null) {
                      active = _hotspots.firstWhere((h) => h.id == _activeId);
                    }

                    return Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Image.asset(
                                'assets/images/hotspot_living_room.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      'Place hotspot_living_room.jpg in assets/images/',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        for (final h in _hotspots)
                          _buildDot(h, width, height, theme),
                        if (active != null)
                          _buildTooltip(active, width, height, theme),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _hotspots.length,
                  itemBuilder: (context, index) {
                    final h = _hotspots[index];
                    final correct = _checked && _isCorrect(h);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: theme.colorScheme.primary,
                            child: Text(
                              h.id.toString(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _controllers[h.id],
                              decoration: InputDecoration(
                                labelText: 'Label for #${h.id}',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_checked)
                            Icon(
                              correct ? Icons.check_circle : Icons.cancel,
                              color: correct
                                  ? Colors.green
                                  : theme.colorScheme.error,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _checkAnswers,
                  child: const Text('Check answers'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(_Hotspot h, double width, double height, ThemeData theme) {
    final radius = 16.0;
    final cx = h.x * width;
    final cy = h.y * height;
    final bool isActive = h.id == _activeId;

    return Positioned(
      left: cx - radius,
      top: cy - radius,
      child: GestureDetector(
        onTap: () => _onHotspotTap(h.id),
        child: Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            h.id.toString(),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isActive
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTooltip(
    _Hotspot h,
    double width,
    double height,
    ThemeData theme,
  ) {
    const tooltipWidth = 180.0;
    const tooltipHeight = 80.0;

    final cx = h.x * width;
    final cy = h.y * height;

    double left = cx + 20;
    double top = cy - tooltipHeight / 2;

    left = math.max(8, math.min(left, width - tooltipWidth - 8));
    top = math.max(8, math.min(top, height - tooltipHeight - 8));

    return Positioned(
      left: left,
      top: top,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface,
        child: Container(
          width: tooltipWidth,
          height: tooltipHeight,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      h.word,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up),
                    onPressed: () => _speak(h.word),
                  ),
                ],
              ),
              Text(
                'Tap dot ${h.id} and write this word below.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hotspot {
  final int id;
  final double x;
  final double y;
  final String word;

  const _Hotspot({
    required this.id,
    required this.x,
    required this.y,
    required this.word,
  });
}
