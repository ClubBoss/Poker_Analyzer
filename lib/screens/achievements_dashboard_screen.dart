import 'package:flutter/material.dart';

import '../models/goal_completion_event.dart';
import '../services/goal_completion_event_service.dart';

class AchievementsDashboardScreen extends StatefulWidget {
  static const route = '/achievements';
  const AchievementsDashboardScreen({super.key});

  @override
  State<AchievementsDashboardScreen> createState() =>
      _AchievementsDashboardScreenState();
}

class _AchievementsDashboardScreenState
    extends State<AchievementsDashboardScreen> {
  late Future<List<GoalCompletionEvent>> _future;

  @override
  void initState() {
    super.initState();
    _future = GoalCompletionEventService.instance.getAllEvents();
  }

  String _format(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final mon = d.month.toString().padLeft(2, '0');
    return '$day.$mon.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История достижений'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<GoalCompletionEvent>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snapshot.data!;
          if (events.isEmpty) {
            return const Center(child: Text('Нет данных'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final e = events[index];
              return _AchievementTile(event: e, dateFormatter: _format);
            },
          );
        },
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final GoalCompletionEvent event;
  final String Function(DateTime) dateFormatter;
  const _AchievementTile({
    required this.event,
    required this.dateFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Цель завершена: ${event.tag}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Дата: ${dateFormatter(event.timestamp)}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
