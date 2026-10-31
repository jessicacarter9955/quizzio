import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wordweaver/services/stats_service.dart';
import 'package:wordweaver/services/quiz_service.dart';
import 'package:wordweaver/services/language_service.dart';
import 'package:wordweaver/services/topic_service.dart';
import 'package:wordweaver/models/quiz_result.dart';
import 'package:wordweaver/services/user_service.dart';
import 'package:wordweaver/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final String _range = 'all'; // all, today, yesterday, 7d, 30d

  @override
  Widget build(BuildContext context) {
    final statsService = StatsService();
    final quizService = QuizService();
    final languageService = LanguageService();
    final topicService = TopicService();
    final userService = UserService();
    final l10n = AppLocalizations.of(context);

    String flagForCode(String code) {
      final lang = languageService.getLanguages().firstWhere(
        (l) => l.code == code,
        orElse: () => languageService.getLanguages().first,
      );
      return lang.flag;
    }

    Widget pairLabel(String key) {
      final parts = key.split('_');
      if (parts.length == 2) {
        final left = flagForCode(parts[0]);
        final right = flagForCode(parts[1]);
        return Row(
          children: [
            Text(left, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward, size: 16),
            const SizedBox(width: 6),
            Text(right, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              '($key)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        );
      }
      return Text(key);
    }

    Widget statCard({
      required String label,
      required String value,
      Color? color,
    }) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color ?? Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    String labelFor(String topicId) {
      try {
        final t = topicService.topics.firstWhere((x) => x.id == topicId);
        return '${t.emoji}  ${t.name}';
      } catch (_) {
        return topicId;
      }
    }

    List<QuizResult> filteredResults(List<QuizResult> results) {
      if (_range == 'all') return results;
      final now = DateTime.now();
      if (_range == 'today') {
        return results.where((r) {
          final d = r.timestamp.toLocal();
          return d.year == now.year && d.month == now.month && d.day == now.day;
        }).toList();
      }
      if (_range == 'yesterday') {
        final yesterday = now.subtract(const Duration(days: 1));
        return results.where((r) {
          final d = r.timestamp.toLocal();
          return d.year == yesterday.year &&
              d.month == yesterday.month &&
              d.day == yesterday.day;
        }).toList();
      }
      final int days = _range == '7d' ? 7 : 30;
      return results
          .where((r) => now.difference(r.timestamp).inDays < days)
          .toList();
    }

    Map<String, dynamic> aggregate(List<QuizResult> results) {
      final int totalQuizzes = results.length;
      int totalQuestions = 0;
      int correct = 0;
      int time = 0;
      final perTopic = <String, Map<String, int>>{};
      final perPair = <String, Map<String, int>>{};
      for (final r in results) {
        totalQuestions += r.totalQuestions;
        correct += r.correctAnswers;
        time += 0; // QuizResult no longer stores timeTaken; keep 0 for now
        for (final t in r.topicIds) {
          perTopic[t] = perTopic[t] ?? {'attempts': 0, 'correct': 0};
          perTopic[t]!['attempts'] =
              (perTopic[t]!['attempts'] ?? 0) + r.totalQuestions;
          perTopic[t]!['correct'] =
              (perTopic[t]!['correct'] ?? 0) + r.correctAnswers;
        }
        perPair[r.languagePairKey] =
            perPair[r.languagePairKey] ?? {'attempts': 0, 'correct': 0};
        perPair[r.languagePairKey]!['attempts'] =
            (perPair[r.languagePairKey]!['attempts'] ?? 0) + r.totalQuestions;
        perPair[r.languagePairKey]!['correct'] =
            (perPair[r.languagePairKey]!['correct'] ?? 0) + r.correctAnswers;
      }
      return {
        'totalQuizzes': totalQuizzes,
        'totalQuestions': totalQuestions,
        'correct': correct,
        'incorrect': totalQuestions - correct,
        'avgTimePerQuestionSec': 0.0,
        'perTopic': perTopic,
        'perPair': perPair,
      };
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Stats',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () async {
              final json = statsService.stats.toJson();
              await Clipboard.setData(ClipboardData(text: json.toString()));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Stats JSON copied to clipboard'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: statsService,
          builder: (context, _) {
            return ListenableBuilder(
              listenable: quizService,
              builder: (context, __) {
                final history = filteredResults(quizService.quizHistory);
                final agg = aggregate(history);
                // Quiz history is saved only when a session finishes. Use the
                // live answer-level StatsService so this page works even after
                // one answered question or an interrupted writing/mnemonic run.
                final live = statsService.stats;
                final hasLiveAnswers = live.totalQuestions > 0;
                final perPair = hasLiveAnswers
                    ? live.perLangPair.map((key, value) => MapEntry(key, {
                          'attempts': value.attempts,
                          'correct': value.correct,
                        }))
                    : agg['perPair'] as Map<String, Map<String, int>>;
                final perPairSorted = perPair.entries.toList()
                  ..sort(
                    (a, b) => (b.value['correct'] ?? 0).compareTo(
                      a.value['correct'] ?? 0,
                    ),
                  );

                final perTopic = hasLiveAnswers
                    ? live.perTopic.map((key, value) => MapEntry(key, {
                          'attempts': value.attempts,
                          'correct': value.correct,
                        }))
                    : agg['perTopic'] as Map<String, Map<String, int>>;
                final topTopics = perTopic.entries.toList()
                  ..sort((a, b) {
                    final aA = (a.value['attempts'] ?? 0);
                    final bA = (b.value['attempts'] ?? 0);
                    final aAcc = aA == 0 ? 0.0 : (a.value['correct'] ?? 0) / aA;
                    final bAcc = bA == 0 ? 0.0 : (b.value['correct'] ?? 0) / bA;
                    return bAcc.compareTo(aAcc);
                  });

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick stats',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      QuickStatsSection(
                        userService: userService,
                        statsService: statsService,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Performance by language',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...perPairSorted.map((e) {
                        final attempts = e.value['attempts'] ?? 0;
                        final corr = e.value['correct'] ?? 0;
                        final acc = attempts == 0
                            ? 0.0
                            : (corr / attempts * 100.0);
                        final parts = e.key.split('_');
                        final from = parts.length == 2
                            ? flagForCode(parts[0])
                            : '';
                        final to = parts.length == 2
                            ? flagForCode(parts[1])
                            : '';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(from, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward, size: 16),
                              const SizedBox(width: 6),
                              Text(to, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${parts.first.toUpperCase()} → ${parts.last.toUpperCase()}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Average score: ${acc.toStringAsFixed(0)}%',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                corr.toString(),
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                      Text(
                        'Top topics',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (topTopics.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'No topic data yet. Play a few quizzes to see topic stats.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                          ),
                        )
                      else
                        Row(
                          children: topTopics.take(3).map((e) {
                            final attempts = e.value['attempts'] ?? 0;
                            final corr = e.value['correct'] ?? 0;
                            final acc = attempts == 0
                                ? 0.0
                                : (corr / attempts * 100.0);
                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      labelFor(e.key),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${acc.toStringAsFixed(0)}% Avg.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$attempts questions reviewed',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.7),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        'Recent sessions',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final recent = quizService.getRecentResults(5);
                          if (recent.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'No recent sessions yet.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                              ),
                            );
                          }
                          return Column(
                            children: recent.map((r) {
                              final acc = r.totalQuestions == 0
                                  ? 0
                                  : (r.correctAnswers / r.totalQuestions * 100)
                                        .toInt();
                              final parts = r.languagePairKey.split('_');
                              final left = parts.length == 2
                                  ? flagForCode(parts[0])
                                  : '';
                              final right = parts.length == 2
                                  ? flagForCode(parts[1])
                                  : '';
                              final dateFormatter = DateFormat.yMMMd(
                                Localizations.localeOf(context).toLanguageTag(),
                              ).add_Hm();
                              final formattedDate = dateFormatter.format(
                                r.timestamp.toLocal(),
                              );
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      left,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.arrow_forward, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      right,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${l10n.commonAccuracy} $acc%  •  ${r.correctAnswers}/${r.totalQuestions}',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            formattedDate,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.7),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class QuickStatsSection extends StatelessWidget {
  final UserService userService;
  final StatsService statsService;

  const QuickStatsSection({
    super.key,
    required this.userService,
    required this.statsService,
  });

  @override
  Widget build(BuildContext context) {
    final legacy = userService.getStatsSummary();
    final live = statsService.stats;
    final oldQuestions = legacy['totalQuestions'] as int? ?? 0;
    final questions = live.totalQuestions > 0
        ? live.totalQuestions
        : oldQuestions;
    final correct = live.totalQuestions > 0
        ? live.correct
        : (legacy['totalCorrectAnswers'] as int? ?? 0);
    final oldQuizzes = legacy['totalQuizzesTaken'] as int? ?? 0;
    final completed = QuizService().quizHistory.length;
    final quizzes = live.totalQuizzes > oldQuizzes
        ? (live.totalQuizzes > completed ? live.totalQuizzes : completed)
        : (oldQuizzes > completed ? oldQuizzes : completed);

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      children: [
        _quickStatCard(
          context,
          label: 'Total quizzes',
          value: quizzes.toString(),
          color: Theme.of(context).colorScheme.primary,
        ),
        _quickStatCard(
          context,
          label: 'Correct answers',
          value: correct.toString(),
        ),
        _quickStatCard(
          context,
          label: 'Total questions',
          value: questions.toString(),
        ),
        _quickStatCard(
          context,
          label: 'Overall accuracy',
          value: questions == 0
              ? '0%'
              : '${(correct / questions * 100).toStringAsFixed(0)}%',
        ),
      ],
    );
  }

  Widget _quickStatCard(
    BuildContext context, {
    required String label,
    required String value,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

