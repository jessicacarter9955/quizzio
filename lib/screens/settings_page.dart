import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:wordweaver/services/theme_service.dart';
import 'package:wordweaver/services/vocabulary_service.dart';
import 'package:wordweaver/services/quiz_service.dart';
import 'package:wordweaver/services/quiz_selection.dart';
import 'package:wordweaver/services/language_service.dart';
import 'package:wordweaver/services/topic_service.dart';
import 'package:wordweaver/services/locale_service.dart';
import 'package:wordweaver/services/ai_settings_service.dart';
import 'package:intl/intl.dart';
import 'package:wordweaver/screens/stats_page.dart';
import 'package:wordweaver/screens/my_list_page.dart';
import 'package:wordweaver/screens/puter_auth_page.dart';
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
              Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
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
              Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
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
              Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
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
              Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
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
              Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                child: SettingsListTile(
                  icon: Icons.mic,
                  title: 'Speech & AI',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AiSettingsPage()),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
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
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final contents = utf8.decode(result.files.single.bytes!);
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

class AiSettingsPage extends StatefulWidget {
  const AiSettingsPage({super.key});

  @override
  State<AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends State<AiSettingsPage> {
  late final AiSettingsService _settings;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _bridgeUrlController;

  @override
  void initState() {
    super.initState();
    _settings = AiSettingsService();
    _apiKeyController = TextEditingController(
      text: _settings.openAiApiKey ?? '',
    );
    _bridgeUrlController = TextEditingController(
      text: _settings.puterBridgeUrl ?? '',
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _bridgeUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Speech & AI',
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
            listenable: _settings,
            builder: (context, _) {
              final usePuter = _settings.usePuterBackend;
              final provider = _settings.provider;

              String? currentKey;
              switch (provider) {
                case AiProvider.openAi:
                  currentKey = _settings.openAiApiKey;
                  break;
                case AiProvider.gemini:
                  currentKey = _settings.geminiApiKey;
                  break;
                case AiProvider.claudeAssembly:
                  currentKey = _settings.claudeAssemblyApiKey;
                  break;
                case AiProvider.none:
                  currentKey = null;
                  break;
                case AiProvider.proxyServer:
                  currentKey = _settings.proxyBaseUrl;
                  break;
              }
              _apiKeyController.text = currentKey ?? '';

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backend mode',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: usePuter,
                      onChanged: (value) => _settings.setUsePuterBackend(value),
                      title: const Text('Use Puter (no API key)'),
                      subtitle: const Text(
                        'Default. Uses Puter.ai as a gateway to OpenAI and other models.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (usePuter) ...[
                      Text(
                        'Puter model',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue:
                            const [
                              'gpt-5-nano',
                              'gpt-5-nano-reasoning',
                              'gpt-4.1-mini',
                              'gpt-4o-mini',
                            ].contains(_settings.puterModel)
                            ? _settings.puterModel
                            : 'gpt-5-nano',
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Model',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'gpt-5-nano',
                            child: Text('gpt-5-nano'),
                          ),
                          DropdownMenuItem(
                            value: 'gpt-5-nano-reasoning',
                            child: Text('gpt-5-nano-reasoning'),
                          ),
                          DropdownMenuItem(
                            value: 'gpt-4.1-mini',
                            child: Text('gpt-4.1-mini'),
                          ),
                          DropdownMenuItem(
                            value: 'gpt-4o-mini',
                            child: Text('gpt-4o-mini'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _settings.setPuterModel(value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Puter bridge URL (optional)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _bridgeUrlController,
                        decoration: const InputDecoration(
                          labelText:
                              'https://your-pages.example.com/puter-bridge/',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          _settings.setPuterBridgeUrl(
                            value.trim().isEmpty ? null : value.trim(),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PuterAuthPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.login),
                          label: const Text('Puter login (optional)'),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Direct provider',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<AiProvider>(
                        initialValue: provider,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Provider',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: AiProvider.openAi,
                            child: Text('OpenAI'),
                          ),
                          DropdownMenuItem(
                            value: AiProvider.gemini,
                            child: Text('Gemini'),
                          ),
                          DropdownMenuItem(
                            value: AiProvider.claudeAssembly,
                            child: Text('Claude/Assembly'),
                          ),
                          DropdownMenuItem(
                            value: AiProvider.none,
                            child: Text('None'),
                          ),
                          DropdownMenuItem(
                            value: AiProvider.proxyServer,
                            child: Text('Custom server (Node/worker)'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _settings.setProvider(value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      if (provider == AiProvider.proxyServer) ...[
                        TextField(
                          controller: _apiKeyController,
                          decoration: const InputDecoration(
                            labelText: 'Server URL (https://...)',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            _settings.setProxyBaseUrl(
                              value.isEmpty ? null : value.trim(),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Example: https://your-worker.example.workers.dev',
                        ),
                      ] else ...[
                        TextField(
                          controller: _apiKeyController,
                          decoration: const InputDecoration(
                            labelText: 'API key',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          onChanged: (value) {
                            switch (provider) {
                              case AiProvider.openAi:
                                _settings.setOpenAiApiKey(
                                  value.isEmpty ? null : value,
                                );
                                break;
                              case AiProvider.gemini:
                                _settings.setGeminiApiKey(
                                  value.isEmpty ? null : value,
                                );
                                break;
                              case AiProvider.claudeAssembly:
                                _settings.setClaudeAssemblyApiKey(
                                  value.isEmpty ? null : value,
                                );
                                break;
                              case AiProvider.none:
                              case AiProvider.proxyServer:
                                break;
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Keys are stored locally on this device. Only OpenAI is wired for chat right now.',
                        ),
                      ],
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
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
      listenable: Listenable.merge([
        _quizService, TopicService(), LanguageService(), VocabularyService(),
      ]),
      builder: (context, _) {
        final pairKey = LanguageService().currentLanguagePairKey;
        final available = QuizSelection.availableTopics(pairKey);
        final selectedIds = TopicService().getSelectedTopics().map((t) => t.id).toSet();
        final base = selectedIds.isEmpty
            ? available : available.where((t) => selectedIds.contains(t.id)).toList();
        final usedTopics = _quizService.topicMode == 'single'
            ? base.take(1) : base;
        final maxQuestions = QuizSelection.wordCount(pairKey, usedTopics.map((t) => t.id));
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
                      key: ValueKey('question-count-$questionCount'),
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
                      items: [
                        DropdownMenuItem(value: 0, child: Text('Max ($maxQuestions)')),
                        const DropdownMenuItem(value: 5, child: Text('5')),
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
                title: Text('Mix selected topics (${QuizSelection.wordCount(pairKey, base.map((t) => t.id))})'),
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
                title: Text('Focus on one topic per quiz ($maxQuestions)'),
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
