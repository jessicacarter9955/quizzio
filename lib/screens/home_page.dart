import 'package:flutter/material.dart';
import 'package:wordweaver/services/language_service.dart';
import 'package:wordweaver/services/topic_service.dart';
import 'package:wordweaver/services/user_service.dart';
import 'package:wordweaver/services/quiz_service.dart';
import 'package:wordweaver/screens/language_setup_page.dart';
import 'package:wordweaver/screens/topic_selection_page.dart';
import 'package:wordweaver/screens/quiz_page.dart';
import 'package:wordweaver/screens/word_match_page.dart';
import 'package:wordweaver/screens/complete_word_page.dart';
import 'package:wordweaver/screens/ruzzle_page.dart';
import 'package:wordweaver/screens/blue_quiz_mock_page.dart';
import 'package:wordweaver/screens/grammar_sentences_page.dart';
import 'package:wordweaver/screens/my_list_page.dart';
import 'package:wordweaver/screens/chat_mock_page.dart';
import 'package:wordweaver/screens/settings_page.dart';
import 'package:wordweaver/screens/image_hotspot_quiz_page.dart';
import 'package:wordweaver/l10n/app_localizations.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageService = LanguageService();
    final topicService = TopicService();
    final userService = UserService();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox.shrink(),
                    Row(
                      children: [
                        LanguagePairPill(languageService: languageService),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyListPage(),
                            ),
                          ),
                          icon: Icon(
                            Icons.bookmark_border,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsPage(),
                            ),
                          ),
                          icon: Icon(
                            Icons.settings,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                CurrentTopicsCard(topicService: topicService),
                const SizedBox(height: 32),
                StartModesButton(
                  topicService: topicService,
                  languageService: languageService,
                ),
                const SizedBox(height: 12),
                const StartConversationButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StartConversationButton extends StatelessWidget {
  const StartConversationButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatMockPage()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          foregroundColor: theme.colorScheme.onSurface,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'Start conversation',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class StartModesButton extends StatelessWidget {
  final TopicService topicService;
  final LanguageService languageService;

  const StartModesButton({
    super.key,
    required this.topicService,
    required this.languageService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quizService = QuizService();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showModePicker(context, quizService),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'Start',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showModePicker(BuildContext context, QuizService quizService) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.45,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (scrollContext, scrollController) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.6,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Text(
                      'Choose a mode',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: [
                          _buildModeTile(
                            sheetContext,
                            icon: Icons.quiz_outlined,
                            title: 'Quiz',
                            subtitle: 'Multiple-choice practice',
                            onTap: () {
                              _startQuiz(context, quizService);
                            },
                          ),
                          _buildModeTile(
                            sheetContext,
                            icon: Icons.spellcheck_outlined,
                            title: 'Complete the word',
                            subtitle: 'Fill in missing letters',
                            onTap: () {
                              _startCompleteWord(context, quizService);
                            },
                          ),
                          _buildModeTile(
                            sheetContext,
                            icon: Icons.record_voice_over_outlined,
                            title: 'Speaking Quiz',
                            subtitle: 'Say the answer out loud',
                            onTap: () {
                              _startQuiz(context, quizService, speaking: true);
                            },
                          ),
                          _buildModeTile(
                            sheetContext,
                            icon: Icons.mic_outlined,
                            title: 'Speaking fill word',
                            subtitle: 'Answer by speaking the word',
                            onTap: () {
                              _startCompleteWord(
                                context,
                                quizService,
                                speaking: true,
                              );
                            },
                          ),
                          _buildModeTile(
                            sheetContext,
                            icon: Icons.grid_4x4_outlined,
                            title: 'Ruzzle',
                            subtitle: 'Find words in the grid',
                            onTap: () {
                              _startRuzzle(context, quizService);
                            },
                          ),
                          _buildModeTile(
                            sheetContext,
                            icon: Icons.palette_outlined,
                            title: 'BLUE quiz',
                            subtitle: 'Design-focused multiple choice',
                            onTap: () {
                              _startBlueQuiz(context, quizService);
                            },
                          ),
                          _buildModeTile(
                            sheetContext,
                            icon: Icons.menu_book_outlined,
                            title: 'Grammar sentences',
                            subtitle: 'View generated sentence pairs',
                            onTap: () {
                              _startGrammarSentences(context);
                            },
                          ),
                          _buildModeTile(
                            sheetContext,
                            icon: Icons.view_column_outlined,
                            title: 'Word Match',
                            subtitle: 'Match translations in pairs',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WordMatchPage(),
                                ),
                              );
                            },
                          ),
                          _buildModeTile(
                            sheetContext,
                            icon: Icons.image_outlined,
                            title: 'Image hotspots',
                            subtitle: 'Tap spots and type labels',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ImageHotspotQuizPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModeTile(
    BuildContext sheetContext, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(sheetContext);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      onTap: () {
        Navigator.pop(sheetContext);
        onTap();
      },
    );
  }

  void _startGrammarSentences(BuildContext context) {
    _startGrammarSentencesInternal(context);
  }

  Future<void> _startGrammarSentencesInternal(
    BuildContext context, {
    bool cameFromRetry = false,
  }) async {
    final pair = languageService.currentLanguagePair;

    if (pair == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LanguageSetupPage()),
      );
      if (cameFromRetry) {
        if (languageService.currentLanguagePair == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please pick a study language to start.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      } else {
        await _startGrammarSentencesInternal(context, cameFromRetry: true);
        return;
      }
    }

    final finalPair = languageService.currentLanguagePair;

    if (finalPair == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick a language.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GrammarSentencesPage(languagePair: finalPair),
      ),
    );
  }

  void _startQuiz(
    BuildContext context,
    QuizService quizService, {
    bool speaking = false,
  }) {
    _startQuizInternal(context, quizService, speaking: speaking);
  }

  Future<void> _startQuizInternal(
    BuildContext context,
    QuizService quizService, {
    bool speaking = false,
    bool cameFromRetry = false,
  }) async {
    final selectedTopics = topicService.getSelectedTopics();
    final allTopics = topicService.topics;
    final baseTopics = selectedTopics.isEmpty ? allTopics : selectedTopics;
    final topicMode = quizService.topicMode;
    final topicsToUse = (topicMode == 'single' && baseTopics.isNotEmpty)
        ? [baseTopics.first]
        : baseTopics;
    final pair = languageService.currentLanguagePair;

    if (pair == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LanguageSetupPage()),
      );
      if (cameFromRetry) {
        if (languageService.currentLanguagePair == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please pick a study language to start.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      } else {
        await _startQuizInternal(
          context,
          quizService,
          speaking: speaking,
          cameFromRetry: true,
        );
        return;
      }
    }

    if (topicsToUse.isEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TopicSelectionPage()),
      );
      if (cameFromRetry) {
        final refreshedSelected = topicService.getSelectedTopics();
        final refreshedAll = topicService.topics;
        final refreshedBase = refreshedSelected.isEmpty
            ? refreshedAll
            : refreshedSelected;
        final refreshedTopicsToUse =
            (topicMode == 'single' && refreshedBase.isNotEmpty)
            ? [refreshedBase.first]
            : refreshedBase;
        if (refreshedTopicsToUse.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select at least one topic to start.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      } else {
        await _startQuizInternal(
          context,
          quizService,
          speaking: speaking,
          cameFromRetry: true,
        );
        return;
      }
    }

    final finalSelected = topicService.getSelectedTopics();
    final finalAll = topicService.topics;
    final finalBase = finalSelected.isEmpty ? finalAll : finalSelected;
    final finalTopicsToUse = (topicMode == 'single' && finalBase.isNotEmpty)
        ? [finalBase.first]
        : finalBase;
    final finalPair = languageService.currentLanguagePair;

    if (finalPair == null || finalTopicsToUse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick a language and at least one topic.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final questionCount = quizService.questionCount;
    final answerOptionCount = quizService.answerOptionCount;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizPage(
          languagePair: finalPair,
          selectedTopics: finalTopicsToUse,
          questionCount: questionCount,
          answerOptionCount: answerOptionCount,
          speakingMode: speaking,
        ),
      ),
    );
  }

  void _startCompleteWord(
    BuildContext context,
    QuizService quizService, {
    bool speaking = false,
  }) {
    _startCompleteWordInternal(context, quizService, speaking: speaking);
  }

  Future<void> _startCompleteWordInternal(
    BuildContext context,
    QuizService quizService, {
    bool speaking = false,
    bool cameFromRetry = false,
  }) async {
    final selectedTopics = topicService.getSelectedTopics();
    final allTopics = topicService.topics;
    final baseTopics = selectedTopics.isEmpty ? allTopics : selectedTopics;
    final topicMode = quizService.topicMode;
    final topicsToUse = (topicMode == 'single' && baseTopics.isNotEmpty)
        ? [baseTopics.first]
        : baseTopics;
    final pair = languageService.currentLanguagePair;

    if (pair == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LanguageSetupPage()),
      );
      if (cameFromRetry) {
        if (languageService.currentLanguagePair == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please pick a study language to start.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      } else {
        await _startCompleteWordInternal(
          context,
          quizService,
          speaking: speaking,
          cameFromRetry: true,
        );
        return;
      }
    }

    if (topicsToUse.isEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TopicSelectionPage()),
      );
      if (cameFromRetry) {
        final refreshedSelected = topicService.getSelectedTopics();
        final refreshedAll = topicService.topics;
        final refreshedBase = refreshedSelected.isEmpty
            ? refreshedAll
            : refreshedSelected;
        final refreshedTopicsToUse =
            (topicMode == 'single' && refreshedBase.isNotEmpty)
            ? [refreshedBase.first]
            : refreshedBase;
        if (refreshedTopicsToUse.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select at least one topic to start.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      } else {
        await _startCompleteWordInternal(
          context,
          quizService,
          speaking: speaking,
          cameFromRetry: true,
        );
        return;
      }
    }

    final finalSelected = topicService.getSelectedTopics();
    final finalAll = topicService.topics;
    final finalBase = finalSelected.isEmpty ? finalAll : finalSelected;
    final finalTopicsToUse = (topicMode == 'single' && finalBase.isNotEmpty)
        ? [finalBase.first]
        : finalBase;
    final finalPair = languageService.currentLanguagePair;

    if (finalPair == null || finalTopicsToUse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick a language and at least one topic.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final questionCount = quizService.questionCount;
    final answerOptionCount = quizService.answerOptionCount;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompleteWordPage(
          languagePair: finalPair,
          selectedTopics: finalTopicsToUse,
          questionCount: questionCount,
          answerOptionCount: answerOptionCount,
          speakingMode: speaking,
        ),
      ),
    );
  }

  void _startRuzzle(BuildContext context, QuizService quizService) {
    _startRuzzleInternal(context, quizService);
  }

  Future<void> _startRuzzleInternal(
    BuildContext context,
    QuizService quizService, {
    bool cameFromRetry = false,
  }) async {
    final selectedTopics = topicService.getSelectedTopics();
    final allTopics = topicService.topics;
    final baseTopics = selectedTopics.isEmpty ? allTopics : selectedTopics;
    final topicMode = quizService.topicMode;
    final topicsToUse = (topicMode == 'single' && baseTopics.isNotEmpty)
        ? [baseTopics.first]
        : baseTopics;
    final pair = languageService.currentLanguagePair;

    if (pair == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LanguageSetupPage()),
      );
      if (cameFromRetry) {
        if (languageService.currentLanguagePair == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please pick a study language to start.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      } else {
        await _startRuzzleInternal(context, quizService, cameFromRetry: true);
        return;
      }
    }

    if (topicsToUse.isEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TopicSelectionPage()),
      );
      if (cameFromRetry) {
        final refreshedSelected = topicService.getSelectedTopics();
        final refreshedAll = topicService.topics;
        final refreshedBase = refreshedSelected.isEmpty
            ? refreshedAll
            : refreshedSelected;
        final refreshedTopicsToUse =
            (topicMode == 'single' && refreshedBase.isNotEmpty)
            ? [refreshedBase.first]
            : refreshedBase;
        if (refreshedTopicsToUse.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select at least one topic to start.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      } else {
        await _startRuzzleInternal(context, quizService, cameFromRetry: true);
        return;
      }
    }

    final finalSelected = topicService.getSelectedTopics();
    final finalAll = topicService.topics;
    final finalBase = finalSelected.isEmpty ? finalAll : finalSelected;
    final finalTopicsToUse = (topicMode == 'single' && finalBase.isNotEmpty)
        ? [finalBase.first]
        : finalBase;
    final finalPair = languageService.currentLanguagePair;

    if (finalPair == null || finalTopicsToUse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick a language and at least one topic.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RuzzlePage(
          languagePair: finalPair,
          selectedTopics: finalTopicsToUse,
        ),
      ),
    );
  }

  void _startBlueQuiz(BuildContext context, QuizService quizService) {
    _startBlueQuizInternal(context, quizService);
  }

  Future<void> _startBlueQuizInternal(
    BuildContext context,
    QuizService quizService, {
    bool cameFromRetry = false,
  }) async {
    final selectedTopics = topicService.getSelectedTopics();
    final allTopics = topicService.topics;
    final baseTopics = selectedTopics.isEmpty ? allTopics : selectedTopics;
    final topicMode = quizService.topicMode;
    final topicsToUse = (topicMode == 'single' && baseTopics.isNotEmpty)
        ? [baseTopics.first]
        : baseTopics;
    final pair = languageService.currentLanguagePair;

    if (pair == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LanguageSetupPage()),
      );
      if (cameFromRetry) {
        if (languageService.currentLanguagePair == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please pick a study language to start.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      } else {
        await _startBlueQuizInternal(context, quizService, cameFromRetry: true);
        return;
      }
    }

    if (topicsToUse.isEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TopicSelectionPage()),
      );
      if (cameFromRetry) {
        final refreshedSelected = topicService.getSelectedTopics();
        final refreshedAll = topicService.topics;
        final refreshedBase = refreshedSelected.isEmpty
            ? refreshedAll
            : refreshedSelected;
        final refreshedTopicsToUse =
            (topicMode == 'single' && refreshedBase.isNotEmpty)
            ? [refreshedBase.first]
            : refreshedBase;
        if (refreshedTopicsToUse.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select at least one topic to start.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      } else {
        await _startBlueQuizInternal(context, quizService, cameFromRetry: true);
        return;
      }
    }

    final finalSelected = topicService.getSelectedTopics();
    final finalAll = topicService.topics;
    final finalBase = finalSelected.isEmpty ? finalAll : finalSelected;
    final finalTopicsToUse = (topicMode == 'single' && finalBase.isNotEmpty)
        ? [finalBase.first]
        : finalBase;
    final finalPair = languageService.currentLanguagePair;

    if (finalPair == null || finalTopicsToUse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick a language and at least one topic.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final questionCount = quizService.questionCount;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlueQuizMockPage(
          languagePair: finalPair,
          selectedTopics: finalTopicsToUse,
          questionCount: questionCount,
        ),
      ),
    );
  }
}

class RuzzleCta extends StatefulWidget {
  final TopicService topicService;
  final LanguageService languageService;

  const RuzzleCta({
    super.key,
    required this.topicService,
    required this.languageService,
  });

  @override
  State<RuzzleCta> createState() => _RuzzleCtaState();
}

class _RuzzleCtaState extends State<RuzzleCta> {
  late final QuizService _quizService;

  @override
  void initState() {
    super.initState();
    _quizService = QuizService();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.topicService,
        widget.languageService,
        _quizService,
      ]),
      builder: (context, _) {
        final selectedTopics = widget.topicService.getSelectedTopics();
        final allTopics = widget.topicService.topics;
        final baseTopics = selectedTopics.isEmpty ? allTopics : selectedTopics;
        final topicMode = _quizService.topicMode;
        final topicsToUse = (topicMode == 'single' && baseTopics.isNotEmpty)
            ? [baseTopics.first]
            : baseTopics;
        final pair = widget.languageService.currentLanguagePair;
        final isEnabled = pair != null && topicsToUse.isNotEmpty;

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isEnabled
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RuzzlePage(
                        languagePair: pair,
                        selectedTopics: topicsToUse,
                      ),
                    ),
                  )
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TopicSelectionPage(),
                    ),
                  ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Play Ruzzle',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        );
      },
    );
  }
}

class LanguagePairPill extends StatelessWidget {
  final LanguageService languageService;

  const LanguagePairPill({super.key, required this.languageService});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageService,
      builder: (context, _) {
        final pair = languageService.currentLanguagePair;
        if (pair == null) {
          // If no pair is selected yet, show a simple icon that opens setup.
          return IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LanguageSetupPage()),
            ),
            icon: Icon(
              Icons.language,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              padding: const EdgeInsets.all(10),
            ),
          );
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LanguageSetupPage()),
            ),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
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
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
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
      },
    );
  }
}

class RecentTopicsSection extends StatelessWidget {
  final TopicService topicService;

  const RecentTopicsSection({super.key, required this.topicService});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: topicService,
      builder: (context, _) {
        final recentTopics = topicService.getRecentTopics();
        if (recentTopics.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              l10n.homeNoTopicsSelectedYet,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          );
        }
        return SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentTopics.length,
            itemBuilder: (context, index) {
              final topic = recentTopics[index];
              return Container(
                width: 120,
                margin: EdgeInsets.only(
                  right: index < recentTopics.length - 1 ? 16 : 0,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        topic.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      topic.name.split(' ')[0],
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class HomeTopicPicker extends StatelessWidget {
  final TopicService topicService;

  const HomeTopicPicker({super.key, required this.topicService});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: topicService,
      builder: (context, _) {
        final topics = topicService.topics;
        if (topics.isEmpty) return const SizedBox.shrink();
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: topics.map((t) {
            final selected = t.isSelected;
            return FilterChip(
              label: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.emoji),
                    const SizedBox(width: 6),
                    Text(t.name, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              selected: selected,
              onSelected: (_) => topicService.toggleTopic(t.id),
              selectedColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.15),
              checkmarkColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              side: BorderSide(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            );
          }).toList(),
        );
      },
    );
  }
}

class StartQuizCta extends StatefulWidget {
  final TopicService topicService;
  final LanguageService languageService;

  const StartQuizCta({
    super.key,
    required this.topicService,
    required this.languageService,
  });

  @override
  State<StartQuizCta> createState() => _StartQuizCtaState();
}

class _StartQuizCtaState extends State<StartQuizCta> {
  late final QuizService _quizService;

  @override
  void initState() {
    super.initState();
    _quizService = QuizService();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.topicService,
        widget.languageService,
        _quizService,
      ]),
      builder: (context, _) {
        final selectedTopics = widget.topicService.getSelectedTopics();
        final allTopics = widget.topicService.topics;
        final baseTopics = selectedTopics.isEmpty ? allTopics : selectedTopics;
        final topicMode = _quizService.topicMode;
        final topicsToUse = (topicMode == 'single' && baseTopics.isNotEmpty)
            ? [baseTopics.first]
            : baseTopics;
        final pair = widget.languageService.currentLanguagePair;
        final isEnabled = pair != null && topicsToUse.isNotEmpty;
        final questionCount = _quizService.questionCount;
        final answerOptionCount = _quizService.answerOptionCount;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isEnabled
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizPage(
                            languagePair: pair,
                            selectedTopics: topicsToUse,
                            questionCount: questionCount,
                            answerOptionCount: answerOptionCount,
                          ),
                        ),
                      )
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TopicSelectionPage(),
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isEnabled ? l10n.homeStartQuiz : l10n.homePickTopicsToStart,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class CompleteWordCta extends StatefulWidget {
  final TopicService topicService;
  final LanguageService languageService;

  const CompleteWordCta({
    super.key,
    required this.topicService,
    required this.languageService,
  });

  @override
  State<CompleteWordCta> createState() => _CompleteWordCtaState();
}

class _CompleteWordCtaState extends State<CompleteWordCta> {
  late final QuizService _quizService;

  @override
  void initState() {
    super.initState();
    _quizService = QuizService();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.topicService,
        widget.languageService,
        _quizService,
      ]),
      builder: (context, _) {
        final selectedTopics = widget.topicService.getSelectedTopics();
        final allTopics = widget.topicService.topics;
        final baseTopics = selectedTopics.isEmpty ? allTopics : selectedTopics;
        final topicMode = _quizService.topicMode;
        final topicsToUse = (topicMode == 'single' && baseTopics.isNotEmpty)
            ? [baseTopics.first]
            : baseTopics;
        final pair = widget.languageService.currentLanguagePair;
        final isEnabled = pair != null && topicsToUse.isNotEmpty;
        final questionCount = _quizService.questionCount;
        final answerOptionCount = _quizService.answerOptionCount;
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: isEnabled
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CompleteWordPage(
                        languagePair: pair,
                        selectedTopics: topicsToUse,
                        questionCount: questionCount,
                        answerOptionCount: answerOptionCount,
                      ),
                    ),
                  )
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TopicSelectionPage(),
                    ),
                  ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              isEnabled
                  ? l10n.homePlayCompleteWord
                  : l10n.homePickTopicsToStart,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}

class CurrentTopicsCard extends StatelessWidget {
  final TopicService topicService;

  const CurrentTopicsCard({super.key, required this.topicService});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: topicService,
      builder: (context, _) {
        final topics = topicService.topics;
        final selected = topicService.getSelectedTopics();
        final showing = selected.isEmpty ? topics : selected;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.homeTopicsSelectedLabel,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withValues(alpha: 0.7),
                              ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TopicSelectionPage(),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.edit,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (showing.isEmpty)
                      Text(
                        l10n.homeNoTopicsAvailable,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                      )
                    else ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: () {
                          // Aim for roughly 3 rows of compact pills.
                          const maxVisible = 12;
                          final hasOverflow = showing.length > maxVisible;
                          final visible = hasOverflow
                              ? showing.take(maxVisible - 1).toList()
                              : showing;

                          final chips = visible.map((t) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surface.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    t.emoji,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    t.name,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                        ),
                                  ),
                                ],
                              ),
                            );
                          }).toList();

                          if (hasOverflow) {
                            final remaining = showing.length - (maxVisible - 1);
                            chips.add(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surface.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '+$remaining',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                      ),
                                ),
                              ),
                            );
                          }

                          return chips;
                        }(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class StartQuizButton extends StatelessWidget {
  final VoidCallback onPressed;

  const StartQuizButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          l10n.commonStartQuiz,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
