import 'package:flutter/material.dart';

import '../services/goal_engagement_tracker.dart';
import '../helpers/date_utils.dart';

class GoalInsightsScreen extends StatefulWidget {
  static const route = '/goal_insights';
  const GoalInsightsScreen({super.key});

  @override
  State<GoalInsightsScreen> createState() => _GoalInsightsScreenState();
}

class _GoalInsightsScreenState extends State<GoalInsightsScreen> {
  bool _loading = true;
  int _started = 0;
  int _completed = 0;
  int _skipped = 0;
  DateTime? _lastActive;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final events = await GoalEngagementTracker.instance.getAll();
    int started = 0;
    int completed = 0;
    int skipped = 0;
    DateTime? last;
    for (final e in events) {
      switch (e.action) {
        case 'start':
          started++;
          break;
        case 'completed':
          completed++;
          break;
        case 'dismiss':
        case 'skip':
          skipped++;
          break;
      }
      if (last == null || e.timestamp.isAfter(last)) last = e.timestamp;
    }
    if (!mounted) return;
    setState(() {
      _started = started;
      _completed = completed;
      _skipped = skipped;
      _lastActive = last;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Статистика целей'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Всего начато целей: $_started'),
                const SizedBox(height: 8),
                Text('Завершено целей: $_completed'),
                const SizedBox(height: 8),
                Text('Пропущено/отклонено: $_skipped'),
                const SizedBox(height: 8),
                Text(
                  'Последняя активность: ${_lastActive != null ? formatDate(_lastActive!) : 'нет'}',
                ),
              ],
            ),
    );
  }
}
