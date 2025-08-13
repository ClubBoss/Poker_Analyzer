import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/tag_mastery_service.dart';
import '../services/skill_boost_log_service.dart';
import '../models/skill_boost_log_entry.dart';

class TagProgressHistoryCard extends StatelessWidget {
  const TagProgressHistoryCard({super.key});

  Future<List<_TagHistory>> _load(BuildContext context) async {
    final mastery = await context.read<TagMasteryService>().computeMastery();
    final service = SkillBoostLogService.instance;
    await service.load();
    final groups = <String, List<SkillBoostLogEntry>>{};
    for (final log in service.logs) {
      final key = log.tag.toLowerCase();
      groups.putIfAbsent(key, () => []).add(log);
    }
    final entries = <_TagHistory>[];
    for (final e in groups.entries) {
      final value = mastery[e.key] ?? 1.0;
      final logs = List<SkillBoostLogEntry>.from(e.value)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      entries.add(_TagHistory(tag: e.key, mastery: value, logs: logs));
    }
    entries.sort((a, b) {
      final cmp = a.mastery.compareTo(b.mastery);
      if (cmp != 0) return cmp;
      return b.logs.length.compareTo(a.logs.length);
    });
    return entries.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_TagHistory>>(
      future: _load(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final list = snapshot.data!;
        final accent = Theme.of(context).colorScheme.secondary;

        Widget chart(_TagHistory data) {
          final spots = <FlSpot>[];
          var i = 0;
          if (data.logs.isNotEmpty) {
            spots.add(
                FlSpot(i.toDouble(), data.logs.first.accuracyBefore * 100));
            for (final log in data.logs) {
              i++;
              spots.add(FlSpot(i.toDouble(), log.accuracyAfter * 100));
            }
          }
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.tag[0].toUpperCase() + data.tag.substring(1),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 40,
                  width: 80,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 100,
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          color: accent,
                          barWidth: 2,
                          isCurved: false,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.show_chart, color: Colors.amberAccent),
                  SizedBox(width: 8),
                  Text(
                    'Skill Growth',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [for (final e in list) chart(e)]),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TagHistory {
  final String tag;
  final double mastery;
  final List<SkillBoostLogEntry> logs;
  _TagHistory({required this.tag, required this.mastery, required this.logs});
}
