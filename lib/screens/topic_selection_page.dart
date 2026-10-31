import 'package:flutter/material.dart';
import 'package:wordweaver/models/topic.dart';
import 'package:wordweaver/services/language_service.dart';
import 'package:wordweaver/services/quiz_selection.dart';
import 'package:wordweaver/services/topic_service.dart';
import 'package:wordweaver/services/vocabulary_service.dart';

/// Only selectable topics are those with real bilingual words for the active
/// source→target direction. Unavailable topics can be viewed but not selected.
class TopicSelectionPage extends StatefulWidget {
  const TopicSelectionPage({super.key});

  @override
  State<TopicSelectionPage> createState() => _TopicSelectionPageState();
}

class _TopicSelectionPageState extends State<TopicSelectionPage> {
  final TopicService topicService = TopicService();
  final VocabularyService vocabularyService = VocabularyService();
  bool _showUnavailable = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait([topicService.ready, vocabularyService.ready]);
    if (LanguageService().currentLanguagePair == null) {
      await LanguageService().initialize();
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: ListenableBuilder(
          listenable: topicService,
          builder: (context, _) {
            final available = QuizSelection.availableTopics(
              LanguageService().currentLanguagePairKey,
            );
            final selected = topicService.getSelectedTopics()
                .where((t) => available.contains(t)).length;
            return Text('Select Topics ($selected)');
          },
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            topicService, vocabularyService, LanguageService(),
          ]),
          builder: (context, _) {
            final pair = LanguageService().currentLanguagePair;
            final key = pair?.key;
            final available = QuizSelection.availableTopics(key);
            final availableIds = available.map((t) => t.id).toSet();
            final topics = topicService.topics.where(
              (t) => _showUnavailable || availableIds.contains(t.id),
            ).toList();
            final total = QuizSelection.wordCount(key, available.map((t) => t.id));
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${pair?.source.flag ?? ''} ${pair?.source.name ?? ''} → '
                        '${pair?.target.flag ?? ''} ${pair?.target.name ?? ''}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Available topics (${available.length}) · Words ($total)',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Show unavailable topics'),
                        value: _showUnavailable,
                        onChanged: (v) => setState(() => _showUnavailable = v),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                    itemCount: topics.length,
                    itemBuilder: (context, index) {
                      final topic = topics[index];
                      final count = key == null ? 0
                          : vocabularyService.getWordCountForTopic(key, topic.id);
                      return TopicCheckboxTile(
                        topic: topic,
                        count: count,
                        enabled: count > 0,
                        onChanged: (_) => topicService.toggleTopic(topic.id),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class TopicCheckboxTile extends StatelessWidget {
  final Topic topic;
  final int count;
  final bool enabled;
  final ValueChanged<bool?> onChanged;

  const TopicCheckboxTile({
    super.key,
    required this.topic,
    required this.count,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: enabled && topic.isSelected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        enabled: enabled,
        onTap: enabled ? () => onChanged(!topic.isSelected) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Text(topic.emoji, style: const TextStyle(fontSize: 22)),
        title: Text('${topic.name} ($count)'),
        subtitle: !enabled ? const Text('Not available for this language pair') : null,
        trailing: Icon(
          enabled && topic.isSelected
              ? Icons.check_circle : Icons.circle_outlined,
          color: enabled && topic.isSelected
              ? theme.colorScheme.primary : theme.colorScheme.outline,
        ),
      ),
    );
  }
}
