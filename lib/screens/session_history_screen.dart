import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../helpers/date_utils.dart';
import '../models/v2/training_session.dart';
import '../models/saved_hand.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/session_note_service.dart';
import '../services/training_stats_service.dart';
import 'session_analysis_screen.dart';
import 'package:provider/provider.dart';
import 'dart:io';

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

  Future<void> _exportNotes() async {
    final notes = context.read<SessionNoteService>();
    final stats = context.read<TrainingStatsService>();
    final path = await notes.exportAsPdf(stats);
    if (path == null || !mounted) return;
    final name = path.split(Platform.pathSeparator).last;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Файл сохранён: $name')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export',
            onPressed: _exportNotes,
          ),
        ],
      ),
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
                  onTap: () {
                    final allHands = context.read<SavedHandManagerService>().hands;
                    final List<SavedHand> sessionHands = [];
                    for (final h in allHands) {
                      final afterStart = !h.savedAt.isBefore(s.startedAt);
                      final beforeEnd = s.completedAt == null || !h.savedAt.isAfter(s.completedAt!);
                      if (afterStart && beforeEnd) sessionHands.add(h);
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SessionAnalysisScreen(hands: sessionHands),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
