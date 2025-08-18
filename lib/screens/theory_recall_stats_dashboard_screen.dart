import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/theory_recall_impact_tracker.dart';
import '../theme/app_colors.dart';

class TheoryRecallStatsDashboardScreen extends StatefulWidget {
  const TheoryRecallStatsDashboardScreen({super.key});

  @override
  State<TheoryRecallStatsDashboardScreen> createState() =>
      _TheoryRecallStatsDashboardScreenState();
}

class _TheoryRecallStatsDashboardScreenState
    extends State<TheoryRecallStatsDashboardScreen> {
  List<TheoryRecallImpactEntry> _entries = [];
  final List<(String, int)> _tagCounts = [];
  final List<(String, int)> _lessonCounts = [];
  final Map<String, List<(String, int)>> _tagLessonCounts = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final entries = TheoryRecallImpactTracker.instance.entries;
    final tagCounts = <String, int>{};
    final lessonCounts = <String, int>{};
    final tagLessonCounts = <String, Map<String, int>>{};
    for (final e in entries) {
      tagCounts[e.tag] = (tagCounts[e.tag] ?? 0) + 1;
      lessonCounts[e.lessonId] = (lessonCounts[e.lessonId] ?? 0) + 1;
      final map = tagLessonCounts.putIfAbsent(e.tag, () => <String, int>{});
      map[e.lessonId] = (map[e.lessonId] ?? 0) + 1;
    }
    List<(String, int)> sortMap(Map<String, int> map) {
      final list = map.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return [for (final e in list) (e.key, e.value)];
    }

    setState(() {
      _entries = entries;
      _tagCounts
        ..clear()
        ..addAll(sortMap(tagCounts));
      _lessonCounts
        ..clear()
        ..addAll(sortMap(lessonCounts));
      _tagLessonCounts
        ..clear()
        ..addAll({
          for (final t in tagLessonCounts.entries) t.key: sortMap(t.value),
        });
    });
  }

  Future<void> _reset() async {
    await TheoryRecallImpactTracker.instance.clear();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Theory Recall Stats')),
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Clear data'),
            value: false,
            onChanged: (_) => _reset(),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Total recalls: ${_entries.length}'),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Most Frequent Tags'),
          for (final t in _tagCounts.take(10))
            ListTile(title: Text(t.$1), trailing: Text('${t.$2}')),
          const SizedBox(height: 16),
          const Text('Most Viewed Lessons'),
          for (final l in _lessonCounts.take(10))
            ListTile(title: Text(l.$1), trailing: Text('${l.$2}')),
          const SizedBox(height: 16),
          for (final entry in _tagLessonCounts.entries)
            ExpansionTile(
              title: Text(
                '${entry.key} (${_tagCounts.firstWhere((t) => t.$1 == entry.key).$2})',
              ),
              children: [
                for (final lesson in entry.value.take(5))
                  ListTile(
                    title: Text(lesson.$1),
                    trailing: Text('${lesson.$2}'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
