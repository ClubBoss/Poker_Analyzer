import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/date_utils.dart';
import '../models/cloud_training_session.dart';
import '../models/session_log.dart';
import '../services/cloud_training_history_service.dart';
import '../services/session_log_service.dart';
import 'cloud_training_session_details_screen.dart';

class RemoteSessionsScreen extends StatefulWidget {
  const RemoteSessionsScreen({super.key});

  @override
  State<RemoteSessionsScreen> createState() => _RemoteSessionsScreenState();
}

class _RemoteSessionsScreenState extends State<RemoteSessionsScreen> {
  List<CloudTrainingSession> _remote = [];
  List<SessionLog> _local = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final remote =
        await context.read<CloudTrainingHistoryService>().loadSessions();
    final local = context.read<SessionLogService>().logs;
    setState(() {
      _remote = remote;
      _local = local;
      _loading = false;
    });
  }

  SessionLog? _match(CloudTrainingSession s) {
    for (final l in _local) {
      if ((l.completedAt.difference(s.date)).abs() <
          const Duration(minutes: 1)) {
        return l;
      }
    }
    return null;
  }

  Future<void> _import(CloudTrainingSession s) async {
    final log = SessionLog(
      sessionId: s.path,
      templateId: '-',
      startedAt: s.date,
      completedAt: s.date,
      correctCount: s.correct,
      mistakeCount: s.mistakes,
      tags: const [],
    );
    await context.read<SessionLogService>().addLog(log);
    _load();
  }

  Future<void> _delete(CloudTrainingSession s) async {
    await context.read<CloudTrainingHistoryService>().deleteSession(s.path);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remote Sessions'),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.sync), onPressed: _load)],
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _remote.isEmpty
              ? const Center(child: Text('No sessions'))
              : ListView.separated(
                  itemCount: _remote.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final s = _remote[index];
                    final local = _match(s);
                    return ListTile(
                      title: Text(
                        formatDateTime(s.date),
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${s.correct}/${s.total} • ${s.accuracy.toStringAsFixed(1)}%${local == null ? ' • new' : ''}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.file_download,
                              color: Colors.white70,
                            ),
                            onPressed: local == null ? () => _import(s) : null,
                          ),
                          IconButton(
                            icon:
                                const Icon(Icons.delete, color: Colors.white70),
                            onPressed: () => _delete(s),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CloudTrainingSessionDetailsScreen(session: s),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
