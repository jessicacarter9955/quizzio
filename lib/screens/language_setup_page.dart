import 'package:flutter/material.dart';
import 'package:wordweaver/models/language.dart';
import 'package:wordweaver/services/language_service.dart';
import 'package:wordweaver/services/vocabulary_service.dart';

class LanguageSetupPage extends StatefulWidget {
  const LanguageSetupPage({super.key});

  @override
  State<LanguageSetupPage> createState() => _LanguageSetupPageState();
}

class _LanguageSetupPageState extends State<LanguageSetupPage> {
  final languageService = LanguageService();
  Language? selectedTarget;
  Language? selectedSource;
  String targetSearchQuery = '';
  String sourceSearchQuery = '';
  int step = 0; // 0 = source (I speak), 1 = target (I want to learn)
  final vocabulary = VocabularyService();
  bool _ready = false;
  bool _showUnavailable = false;

  int _sourceCount(Language lang) {
    var best = 0;
    for (final target in Language.supported) {
      if (target.code == lang.code) continue;
      final count = vocabulary.getPairWordCount(lang.code, target.code);
      if (count > best) best = count;
    }
    return best;
  }

  @override
  void initState() {
    super.initState();
    vocabulary.ready.then((_) {
      if (mounted) setState(() => _ready = true);
    });
    final currentPair = languageService.currentLanguagePair;
    if (currentPair != null) {
      selectedTarget = currentPair.targetLanguage;
      selectedSource = currentPair.sourceLanguage;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          step == 0 ? 'I speak…' : 'I want to learn…',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: !_ready ? const Center(child: CircularProgressIndicator()) : SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: SingleChildScrollView(
                  key: ValueKey(step),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (step == 0) ...[
                        Text(
                          'I speak…',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 16),
                        SearchBar(
                          hintText: 'Search for a language',
                          leading: Icon(
                            Icons.search,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          onChanged: (value) =>
                              setState(() => sourceSearchQuery = value),
                          backgroundColor: WidgetStateProperty.all(
                            Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),
                          elevation: WidgetStateProperty.all(0),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Show unavailable languages'),
                          value: _showUnavailable,
                          onChanged: (v) => setState(() => _showUnavailable = v),
                        ),
                        const SizedBox(height: 16),
                        ...languageService
                            .searchLanguages(sourceSearchQuery)
                            .where((lang) => _showUnavailable || _sourceCount(lang) > 0)
                            .map(
                              (lang) => LanguageListTile(
                                language: lang,
                                isSelected: selectedSource?.code == lang.code,
                                count: _sourceCount(lang),
                                available: _sourceCount(lang) > 0,
                                onTap: () =>
                                    setState(() => selectedSource = lang),
                              ),
                            ),
                      ] else ...[
                        Text(
                          'I want to learn…',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 16),
                        SearchBar(
                          hintText: 'Search for a language',
                          leading: Icon(
                            Icons.search,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          onChanged: (value) =>
                              setState(() => targetSearchQuery = value),
                          backgroundColor: WidgetStateProperty.all(
                            Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),
                          elevation: WidgetStateProperty.all(0),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Show unavailable languages'),
                          value: _showUnavailable,
                          onChanged: (v) => setState(() => _showUnavailable = v),
                        ),
                        const SizedBox(height: 16),
                        ...languageService
                            .searchLanguages(targetSearchQuery)
                            .where((lang) => lang.code != selectedSource?.code)
                            .where((lang) => _showUnavailable ||
                                vocabulary.getPairWordCount(selectedSource?.code ?? '', lang.code) > 0)
                            .map(
                              (lang) => LanguageListTile(
                                language: lang,
                                isSelected: selectedTarget?.code == lang.code,
                                count: vocabulary.getPairWordCount(selectedSource?.code ?? '', lang.code),
                                available: vocabulary.getPairWordCount(selectedSource?.code ?? '', lang.code) > 0,
                                onTap: () =>
                                    setState(() => selectedTarget = lang),
                              ),
                            ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (step == 1)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => step = 0),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        child: Text(
                          'Back',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                    ),
                  if (step == 1) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (step == 0
                          ? selectedSource != null && _sourceCount(selectedSource!) > 0
                          : selectedTarget != null && selectedSource != null &&
                              vocabulary.getPairWordCount(selectedSource!.code, selectedTarget!.code) > 0)
                          ? () async {
                        if (step == 0) {
                          if (selectedSource != null) {
                            setState(() => step = 1);
                          }
                        } else {
                          if (selectedTarget != null &&
                              selectedSource != null) {
                            await languageService.setLanguagePair(
                              selectedSource!,
                              selectedTarget!,
                            );
                            if (context.mounted) Navigator.pop(context);
                          }
                        }
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        disabledBackgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                      ),
                      child: Text(
                        step == 0 ? 'Next' : 'Continue',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LanguageListTile extends StatelessWidget {
  final Language language;
  final bool isSelected;
  final VoidCallback onTap;
  final int count;
  final bool available;

  const LanguageListTile({
    super.key,
    required this.language,
    required this.isSelected,
    required this.onTap,
    this.count = 0,
    this.available = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
      ),
      child: ListTile(
        enabled: available,
        onTap: available ? onTap : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Text(language.flag, style: const TextStyle(fontSize: 28)),
        title: Text(
          language.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          '${language.nativeName} · ($count)${available ? '' : ' unavailable'}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8)
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.onPrimary,
              )
            : Icon(
                Icons.circle_outlined,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
      ),
    );
  }
}
