import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/date_utils.dart';
import '../models/session_summary.dart';
import '../services/cloud_training_history_service.dart';

class CloudTrainingHistoryScreen extends StatefulWidget {
  const CloudTrainingHistoryScreen({super.key});

  @override
  State<CloudTrainingHistoryScreen> createState() => _CloudTrainingHistoryScreenState();
}

class _CloudTrainingHistoryScreenState extends State<CloudTrainingHistoryScreen> {
  List<SessionSummary> _sessions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = context.read<CloudTrainingHistoryService>();
    final sessions = await service.loadSessions();
    if (mounted) {
      setState(() => _sessions = sessions);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud History'),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      body: _sessions.isEmpty
          ? const Center(child: Text('История пуста'))
          : ListView.separated(
              itemCount: _sessions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final s = _sessions[index];
                return ListTile(
                  title: Text(
                    formatDateTime(s.date),
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${s.correct}/${s.total} • ${s.accuracy.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              },
            ),
    );
  }
}
