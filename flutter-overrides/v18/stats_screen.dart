import 'package:flutter/material.dart';
import '../main.dart';
import 'shared.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String? selectedTopic;

  int value(Map<String, Object?> row, String key) => (row[key] as num?)?.toInt() ?? 0;
  String pct(int correct, int total) => total == 0 ? '—' : '${(correct * 100 / total).round()}%';

  @override
  Widget build(BuildContext context) {
    final state = StudyScope.of(context);
    final snapshot = Future.wait([
      state.db.dailyStats(), state.db.topicStats(), state.db.questionStats(),
      state.db.languageDirectionStats(),
    ]);
    return FutureBuilder<List<List<Map<String, Object?>>>>(
      future: snapshot,
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Statistics error: ${snap.error}'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final days = snap.data![0];
        final topics = snap.data![1];
        final questionRanks = snap.data![2];
        final languagePairs = snap.data![3];
        final labels = {for (final q in [...state.normalQuestions, ...state.languageQuestions()]) q.itemKey: q.prompt};
        final wordHistory = topics.where((r) => r['topic'].toString().startsWith('Languages / ') &&
            !r['topic'].toString().startsWith('Languages / Phrasebook /')).toList();
        final phraseHistory = topics.where((r) => r['topic'].toString().startsWith('Languages / Phrasebook /')).toList();
        final wordAttemptCount = wordHistory.fold<int>(0, (sum,r) => sum + value(r,'attempts'));
        final phraseAttemptCount = phraseHistory.fold<int>(0, (sum,r) => sum + value(r,'attempts'));
        final allCount = days.fold<int>(0, (sum, d) => sum + value(d, 'attempts'));
        final allCorrect = days.fold<int>(0, (sum, d) => sum + value(d, 'correct'));
        final mastered = state.progress.values.where((p) => p.mastered).length;
        final totalMs = days.fold<int>(0, (sum, d) => sum + value(d, 'elapsed_ms'));
        final dateKeys = days.map((d) => d['day'].toString()).toSet();
        var streak = 0;
        var day = DateTime.now();
        final todayKey = '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        if (!dateKeys.contains(todayKey)) day = day.subtract(const Duration(days: 1));
        while (true) {
          final key = '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
          if (!dateKeys.contains(key)) break;
          streak++;
          day = DateTime(day.year, day.month, day.day - 1);
        }
        final maxDay = days.isEmpty ? 1 :
          days.map((r) => value(r, 'attempts')).reduce((a, b) => a > b ? a : b).clamp(1, 999999);
        final filteredRanks = questionRanks.where((row) =>
            selectedTopic == null || row['topic'] == selectedTopic).toList();
        return ListView(padding: const EdgeInsets.fromLTRB(18, 10, 18, 28), children: [
          const SectionTitle('Statistics', subtitle: 'Persistent history, study consistency and topic rankings.'),
          GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
            childAspectRatio: 1.25, children: [
              NumberCard('$allCount', 'Total answers', Icons.fact_check),
              NumberCard(pct(allCorrect, allCount), 'Accuracy', Icons.track_changes),
              NumberCard('$streak', 'Day streak', Icons.local_fire_department, tint: yellow),
              NumberCard('$mastered', 'Mastered items', Icons.verified, tint: green),
            ]),
          const SizedBox(height: 10),
          Text('Study time: ${(totalMs / 60000).toStringAsFixed(1)} minutes',
              style: const TextStyle(color: muted)),
          const SectionTitle('By day'),
          Panel(child: days.isEmpty ? const Text('No answers yet. Start your first quiz!') :
            Column(children: [
              SizedBox(height: 135, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (final d in days.take(7).toList().reversed) Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Text('${value(d, 'attempts')}', style: const TextStyle(fontSize: 11)),
                    const SizedBox(height: 5),
                    Flexible(child: FractionallySizedBox(
                      heightFactor: value(d, 'attempts') / maxDay,
                      alignment: Alignment.bottomCenter,
                      child: Container(decoration: BoxDecoration(
                          color: cyan, borderRadius: BorderRadius.circular(6))))),
                    const SizedBox(height: 7),
                    Text(d['day'].toString().substring(5), style: const TextStyle(color: muted, fontSize: 10)),
                  ]),
                )),
              ])),
              const SizedBox(height: 12),
              for (final d in days.take(14)) Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Expanded(child: Text('${d['day']}', style: const TextStyle(fontSize: 13))),
                  Text('${value(d, 'attempts')} answers', style: const TextStyle(color: muted, fontSize: 12)),
                  const SizedBox(width: 10),
                  Text(pct(value(d, 'correct'), value(d, 'attempts')),
                    style: const TextStyle(color: cyan, fontWeight: FontWeight.bold)),
                ]),
              ),
            ])),
          const SectionTitle('Vocabulary vs phrasebook', subtitle: 'Answers are counted separately, across all language directions.'),
          Panel(child: Row(children: [
            Expanded(child: NumberCard('$wordAttemptCount', 'Word answers', Icons.menu_book)),
            const SizedBox(width: 10),
            Expanded(child: NumberCard('$phraseAttemptCount', 'Phrase answers', Icons.record_voice_over)),
          ])),
          const SectionTitle('Recall vs Copy writing', subtitle: 'Copy uses the visible model; both keep independent statistics and never alter quiz mastery.'),
          Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final kind in const ['words','phrases']) ...[
              for (final mode in const ['recall','copy']) Builder(builder: (context) {
                final a=state.writingAttempts.where((item)=>item['kind']==kind && (item['mode']??'recall')==mode).toList();
                final yes=a.where((item)=>item['outcome']=='correct').length;
                final no=a.where((item)=>item['outcome']=='wrong').length;
                final skipped=a.where((item)=>item['outcome']=='revealed').length;
                return Padding(padding: const EdgeInsets.symmetric(vertical: 7),child:Column(
                  crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Text('${kind=='words'?'Vocabulary':'Phrasebook'} · ${mode=='copy'?'Copy':'Recall'}',
                      style:const TextStyle(fontWeight:FontWeight.bold)),
                    Text('${a.length} attempts · $yes correct · $no wrong · $skipped skipped',
                      style:const TextStyle(color:muted,fontSize:12)),
                    for(final lang in <String>{for(final e in a) '${e['source']}→${e['target']}'}.toList()..sort())
                      Text('$lang · ${a.where((e)=>'${e['source']}→${e['target']}'==lang).length} attempts',
                        style:const TextStyle(color:muted,fontSize:11)),
                ]));
              }),
            ],
          ])),
          const SectionTitle('Manual similarity colors',subtitle: 'Independent from quiz and writing results.'),
          Panel(child: Column(children: [
            for (final k in const ['green','yellow','red','neutral']) Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),child: Row(children: [
                Icon(Icons.circle,size:12,color:k=='green'?green:k=='yellow'?yellow:k=='red'?red:muted),
                const SizedBox(width: 8),
                Expanded(child: Text(k=='green'?'Very similar':k=='yellow'?'Similar':k=='red'?'Different':'Neutral')),
                Text('${state.terms.where((t)=>t.kind!='phrase' && state.manualColor(t)==k).length} words'),
              ])),
          ])),
          const SectionTitle('Topics ranked by accuracy', subtitle: 'Weakest topics at the top.'),
          if (topics.isEmpty) const Panel(child: Text('Topic statistics will appear after your first answer.')),
          for (var i = 0; i < topics.length; i++) Padding(padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(onTap: () => setState(() => selectedTopic = topics[i]['topic'].toString()),
              child: Panel(child: Row(children: [
                SizedBox(width: 31, child: Text('#${i + 1}', style: const TextStyle(color: muted))),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(topics[i]['topic'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${value(topics[i], 'attempts')} answers • ${value(topics[i], 'reviewed_items')} questions',
                    style: const TextStyle(color: muted, fontSize: 12)),
                ])),
                Text(pct(value(topics[i], 'correct'), value(topics[i], 'attempts')),
                  style: const TextStyle(color: cyan, fontWeight: FontWeight.bold)),
              ])),
            )),
          const SectionTitle('Language directions', subtitle: 'Each source → target pair has independent progress.'),
          if (languagePairs.isEmpty) const Panel(child: Text('No language answers yet.')),
          for (final pair in languagePairs) Padding(padding: const EdgeInsets.only(bottom: 8), child: Panel(
            child: Row(children: [
              const Icon(Icons.translate, color: cyan),
              const SizedBox(width: 12),
              Expanded(child: Text('${pair['source_lang']} → ${pair['target_lang']}',
                style: const TextStyle(fontWeight: FontWeight.bold))),
              Text('${value(pair, 'attempts')} • ${pct(value(pair, 'correct'), value(pair, 'attempts'))}',
                style: const TextStyle(color: muted)),
            ]),
          )),
          const SectionTitle('Most missed questions'),
          Row(children: [
            Expanded(child: DropdownButtonFormField<String>(
              initialValue: selectedTopic ?? 'All',
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Rankings filter'),
              items: ['All', ...topics.map((r) => r['topic'].toString())].map((t) =>
                  DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) => setState(() => selectedTopic = v == 'All' ? null : v),
            )),
          ]),
          const SizedBox(height: 10),
          for (var i = 0; i < filteredRanks.length && i < 50; i++)
            Padding(padding: const EdgeInsets.only(bottom: 8), child: Panel(
              child: Row(children: [
                Text('${i + 1}.', style: const TextStyle(color: muted)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(labels[filteredRanks[i]['item_id']] ?? filteredRanks[i]['item_id'].toString(), maxLines: 2,
                    overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                  Text('${filteredRanks[i]['topic']}', style: const TextStyle(fontSize: 11, color: muted)),
                ])),
                Text('${value(filteredRanks[i], 'wrong')} wrong',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: red)),
              ]),
            )),
          if (filteredRanks.isEmpty) const Panel(child: Text('No answered questions match this topic.')),
        ]);
      },
    );
  }
}