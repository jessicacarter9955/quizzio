import 'package:flutter/material.dart';
import 'package:wordweaver/services/topic_service.dart';

class TopicSelectionPage extends StatelessWidget {
  const TopicSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final topicService = TopicService();

    return Scaffold(
      appBar: AppBar(
        title: ListenableBuilder(
          listenable: topicService,
          builder: (context, _) {
            final selectedCount = topicService.getSelectedTopics().length;
            final baseTitle = 'Select Topics';
            final title = selectedCount > 0
                ? '$baseTitle ($selectedCount)'
                : baseTitle;
            return Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            );
          },
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select one or more topics to begin.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ListenableBuilder(
                      listenable: topicService,
                      builder: (context, _) {
                        return Column(
                          children: topicService.topics
                              .map(
                                (topic) => TopicCheckboxTile(
                                  topic: topic,
                                  onChanged: (value) =>
                                      topicService.toggleTopic(topic.id),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TopicCheckboxTile extends StatelessWidget {
  final dynamic topic;
  final ValueChanged<bool?> onChanged;

  const TopicCheckboxTile({
    super.key,
    required this.topic,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: topic.isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: topic.isSelected
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
      ),
      child: ListTile(
        onTap: () => onChanged(!topic.isSelected),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Text(topic.emoji, style: const TextStyle(fontSize: 22)),
        title: Text(
          topic.name,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: topic.isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        trailing: topic.isSelected
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
