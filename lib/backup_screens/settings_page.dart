import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:wordweaver/services/theme_service.dart';
import 'package:wordweaver/services/vocabulary_service.dart';
import 'package:wordweaver/services/quiz_service.dart';
import 'package:wordweaver/services/locale_service.dart';
import 'package:intl/intl.dart';
import 'package:wordweaver/screens/stats_page.dart';
import 'package:wordweaver/screens/my_list_page.dart';
import 'package:wordweaver/l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();
    final vocabularyService = VocabularyService();

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settingsSectionGeneral,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListenableBuilder(
                  listenable: themeService,
                  builder: (context, _) => SwitchListTile(
                    value: themeService.themeMode == ThemeMode.dark,
                    onChanged: (value) => themeService.toggleTheme(),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        themeService.themeMode == ThemeMode.dark
                            ? Icons.dark_mode
                            : Icons.light_mode,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      l10n.settingsDarkMode,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    activeThumbColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.settingsSectionLanguage,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SettingsListTile(
                  icon: Icons.language,
                  title: l10n.settingsLanguageLabel,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AppLanguagePage()),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.settingsSectionQuizSettings,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SettingsListTile(
                  icon: Icons.tune,
                  title: l10n.settingsQuizSettingsTile,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QuizSettingsPage()),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.settingsSectionDataManagement,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    SettingsListTile(
                      icon: Icons.bookmark_border,
                      title: l10n.myListTitle,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyListPage()),
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                    SettingsListTile(
                      icon: Icons.bar_chart,
                      title: l10n.settingsViewStats,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StatsPage()),
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                    ListTile(
                      onTap: () => _loadVocabulary(context, vocabularyService),
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.upload_file,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        l10n.settingsLoadVocabulary,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: ListenableBuilder(
                        listenable: vocabularyService,
                        builder: (context, _) {
                          final lastUpdated = vocabularyService.lastUpdated;
                          return Text(
                            lastUpdated != null
                                ? l10n.settingsLastUpdated(
                                    DateFormat(
                                      'yyyy-MM-dd, HH:mm',
                                    ).format(lastUpdated),
                                  )
                                : l10n.settingsLastUpdatedNever,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                            textAlign: TextAlign.center,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.settingsSectionSupport,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    SettingsListTile(
                      icon: Icons.help_outline,
                      title: l10n.settingsHelpSupport,
                      onTap: () => _showComingSoon(context),
                    ),
                    Divider(
                      height: 1,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                    SettingsListTile(
                      icon: Icons.info_outline,
                      title: l10n.settingsAbout,
                      onTap: () => _showAbout(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadVocabulary(
    BuildContext context,
    VocabularyService vocabularyService,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final contents = await file.readAsString();
        final Map<String, dynamic> data =
            jsonDecode(contents) as Map<String, dynamic>;

        await vocabularyService.importFromJson(data);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Vocabulary imported successfully!'),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing vocabulary: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.settingsComingSoonTitle),
          content: Text(l10n.settingsComingSoonBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonOk),
            ),
          ],
        );
      },
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.settingsAboutTitle),
          content: Text(l10n.settingsAboutBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonOk),
            ),
          ],
        );
      },
    );
  }
}

class QuizSettingsPage extends StatelessWidget {
  const QuizSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quiz Settings',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: QuizSettingsSection(),
        ),
      ),
    );
  }
}

class QuizSettingsSection extends StatefulWidget {
  const QuizSettingsSection({super.key});

  @override
  State<QuizSettingsSection> createState() => _QuizSettingsSectionState();
}

class _QuizSettingsSectionState extends State<QuizSettingsSection> {
  late final QuizService _quizService;

  @override
  void initState() {
    super.initState();
    _quizService = QuizService();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _quizService,
      builder: (context, _) {
        final questionCount = _quizService.questionCount;
        final answerOptionCount = _quizService.answerOptionCount;
        final topicMode = _quizService.topicMode;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quiz length',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: questionCount,
                      decoration: InputDecoration(
                        labelText: 'Questions per quiz',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 5, child: Text('5')),
                        DropdownMenuItem(value: 10, child: Text('10')),
                        DropdownMenuItem(value: 15, child: Text('15')),
                        DropdownMenuItem(value: 20, child: Text('20')),
                        DropdownMenuItem(value: 30, child: Text('30')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _quizService.setQuestionCount(value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: answerOptionCount,
                      decoration: InputDecoration(
                        labelText: 'Wrong answers',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1')),
                        DropdownMenuItem(value: 2, child: Text('2')),
                        DropdownMenuItem(value: 3, child: Text('3')),
                        DropdownMenuItem(value: 4, child: Text('4')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _quizService.setAnswerOptionCount(value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Topic mixing',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              RadioListTile<String>(
                value: 'mixed',
                groupValue: topicMode,
                onChanged: (value) {
                  if (value != null) {
                    _quizService.setTopicMode(value);
                  }
                },
                title: const Text('Mix all selected topics in one quiz'),
                dense: true,
              ),
              RadioListTile<String>(
                value: 'single',
                groupValue: topicMode,
                onChanged: (value) {
                  if (value != null) {
                    _quizService.setTopicMode(value);
                  }
                },
                title: const Text(
                  'Focus on one topic per quiz (from selected)',
                ),
                dense: true,
              ),
            ],
          ),
        );
      },
    );
  }
}

class SettingsListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const SettingsListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }
}

class AppLanguagePage extends StatelessWidget {
  const AppLanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeService = LocaleService();
    final theme = Theme.of(context);

    const appLanguages = [
      {'code': 'en', 'label': 'English'},
      {'code': 'es', 'label': 'Español'},
      {'code': 'it', 'label': 'Italiano'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.settingsLanguageLabel,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListenableBuilder(
            listenable: localeService,
            builder: (context, _) {
              final currentCode = localeService.locale?.languageCode ?? 'en';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingsLanguageLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose the language for the app interface. This does not change the languages you are learning.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: appLanguages.map((entry) {
                        final code = entry['code']!;
                        final label = entry['label']!;
                        return RadioListTile<String>(
                          value: code,
                          groupValue: currentCode,
                          onChanged: (value) {
                            if (value != null) {
                              localeService.setLocaleCode(value);
                            }
                          },
                          title: Text(
                            label,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
