import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../helpers/date_utils.dart';
import '../models/v2/training_session.dart';

class SessionHistoryScreen extends StatefulWidget {
  const SessionHistoryScreen({super.key});

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  final List<TrainingSession> _sessions = [];
  Box<dynamic>? _box;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!Hive.isBoxOpen('sessions')) {
      await Hive.initFlutter();
      _box = await Hive.openBox('sessions');
    } else {
      _box = Hive.box('sessions');
    }
    final List<TrainingSession> list = [];
    for (final value in _box!.values) {
      if (value is Map) {
        list.add(
          TrainingSession.fromJson(
            Map<String, dynamic>.from(value),
          ),
        );
      }
    }
    list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    setState(() {
      _sessions
        ..clear()
        ..addAll(list);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session History')),
      backgroundColor: const Color(0xFF1B1C1E),
      body: _sessions.isEmpty
          ? const Center(
              child: Text(
                'No sessions',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.builder(
              itemCount: _sessions.length,
              itemBuilder: (context, index) {
                final s = _sessions[index];
                final correct = s.results.values.where((e) => e).length;
                return Card(
                  color: const Color(0xFF2A2B2D),
                  child: ListTile(
                    title: Text(
                      s.templateId,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start: ${formatDateTime(s.startedAt)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        if (s.completedAt != null)
                          Text(
                            'End: ${formatDateTime(s.completedAt!)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        Text(
                          'Correct: $correct / ${s.results.length}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
