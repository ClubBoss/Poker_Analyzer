import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';

import '../helpers/date_utils.dart';
import '../models/session_summary.dart';
import '../services/cloud_training_history_service.dart';

enum _SortOption { newest, oldest, accuracyDesc, accuracyAsc }

class CloudTrainingHistoryScreen extends StatefulWidget {
  const CloudTrainingHistoryScreen({super.key});

  @override
  State<CloudTrainingHistoryScreen> createState() => _CloudTrainingHistoryScreenState();
}

class _CloudTrainingHistoryScreenState extends State<CloudTrainingHistoryScreen> {
  List<SessionSummary> _sessions = [];
  _SortOption _sort = _SortOption.newest;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = context.read<CloudTrainingHistoryService>();
    final sessions = await service.loadSessions();
    _sortList(sessions);
    if (mounted) {
      setState(() => _sessions = sessions);
    }
  }

  void _sortList(List<SessionSummary> list) {
    switch (_sort) {
      case _SortOption.newest:
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
      case _SortOption.oldest:
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case _SortOption.accuracyDesc:
        list.sort((a, b) => b.accuracy.compareTo(a.accuracy));
        break;
      case _SortOption.accuracyAsc:
        list.sort((a, b) => a.accuracy.compareTo(b.accuracy));
        break;
    }
  }

  Future<void> _exportMarkdown() async {
    if (_sessions.isEmpty) return;

    final buffer = StringBuffer();
    for (final s in _sessions) {
      buffer.writeln(
          '- ${formatDateTime(s.date)}: ${s.correct}/${s.total} (${s.accuracy.toStringAsFixed(1)}%)');
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/cloud_history.md');
    await file.writeAsString(buffer.toString());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('История сохранена в cloud_history.md')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud History'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export',
            onPressed: _sessions.isEmpty ? null : _exportMarkdown,
          ),
          PopupMenuButton<_SortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sort = value;
                _sortList(_sessions);
              });
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _SortOption.newest,
                child: Text('Newest'),
              ),
              PopupMenuItem(
                value: _SortOption.oldest,
                child: Text('Oldest'),
              ),
              PopupMenuItem(
                value: _SortOption.accuracyDesc,
                child: Text('Best Accuracy'),
              ),
              PopupMenuItem(
                value: _SortOption.accuracyAsc,
                child: Text('Worst Accuracy'),
              ),
            ],
          )
        ],
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
