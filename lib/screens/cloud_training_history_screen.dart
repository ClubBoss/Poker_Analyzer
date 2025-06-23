import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_saver/file_saver.dart';

import '../helpers/date_utils.dart';
import '../models/cloud_training_session.dart';
import '../services/cloud_sync_service.dart';
import 'training_pack_screen.dart';

class TrainingHistoryScreen extends StatefulWidget {
  const TrainingHistoryScreen({super.key});

  @override
  State<TrainingHistoryScreen> createState() => _TrainingHistoryScreenState();
}

class _TrainingHistoryScreenState extends State<TrainingHistoryScreen> {
  List<CloudTrainingSession> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = context.read<CloudSyncService>();
    final sessions = await service.loadTrainingSessions();
    setState(() {
      _sessions = sessions;
      _loading = false;
    });
  }

  void _openSession(CloudTrainingSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingAnalysisScreen(results: session.results),
      ),
    );
  }

  Future<void> _exportMarkdown() async {
    if (_sessions.isEmpty) return;
    final buffer = StringBuffer();
    for (final s in _sessions) {
      buffer.writeln(
          '- ${formatDateTime(s.date)}: ${s.accuracy.toStringAsFixed(1)}% — Ошибок: ${s.mistakes}');
    }
    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    try {
      await FileSaver.instance.saveAs(
        name: 'training_history',
        bytes: bytes,
        ext: 'md',
        mimeType: MimeType.other,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('История сохранена в training_history.md')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ошибка экспорта')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История тренировок'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Экспорт',
            onPressed: _sessions.isEmpty ? null : _exportMarkdown,
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? const Center(
                  child: Text('История пуста',
                      style: TextStyle(color: Colors.white70)),
                )
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
                        '${s.accuracy.toStringAsFixed(1)}% • Ошибок: ${s.mistakes}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                      onTap: () => _openSession(s),
                    );
                  },
                ),
    );
  }
}
