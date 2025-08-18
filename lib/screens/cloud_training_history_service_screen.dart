import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

import '../helpers/date_utils.dart';
import '../models/cloud_history_entry.dart';
import '../services/cloud_training_history_service.dart';
import '../services/cloud_training_session_import_service.dart';
import '../widgets/sync_status_widget.dart';

enum _SortOption { newest, oldest, accuracyDesc, accuracyAsc }

class CloudTrainingHistoryScreen extends StatefulWidget {
  const CloudTrainingHistoryScreen({super.key});

  @override
  State<CloudTrainingHistoryScreen> createState() =>
      _CloudTrainingHistoryScreenState();
}

class _CloudTrainingHistoryScreenState
    extends State<CloudTrainingHistoryScreen> {
  List<CloudHistoryEntry> _sessions = [];
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

  void _sortList(List<CloudHistoryEntry> list) {
    switch (_sort) {
      case _SortOption.newest:
        list.sort((a, b) => b.summary.date.compareTo(a.summary.date));
        break;
      case _SortOption.oldest:
        list.sort((a, b) => a.summary.date.compareTo(b.summary.date));
        break;
      case _SortOption.accuracyDesc:
        list.sort((a, b) => b.summary.accuracy.compareTo(a.summary.accuracy));
        break;
      case _SortOption.accuracyAsc:
        list.sort((a, b) => a.summary.accuracy.compareTo(b.summary.accuracy));
        break;
    }
  }

  Future<void> _exportMarkdown() async {
    if (_sessions.isEmpty) return;

    final buffer = StringBuffer();
    for (final s in _sessions) {
      final sum = s.summary;
      buffer.writeln(
        '- ${formatDateTime(sum.date)}: ${sum.correct}/${sum.total} (${sum.accuracy.toStringAsFixed(1)}%)',
      );
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

  Future<void> _importJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    final file = File(path);
    final service = CloudTrainingSessionImportService();
    final session = await service.importFromJson(file);
    if (session == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid file')));
      }
      return;
    }
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${formatDateTime(session.date)}')),
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
          SyncStatusIcon.of(context),
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import JSON',
            onPressed: _importJson,
          ),
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
              PopupMenuItem(value: _SortOption.newest, child: Text('Newest')),
              PopupMenuItem(value: _SortOption.oldest, child: Text('Oldest')),
              PopupMenuItem(
                value: _SortOption.accuracyDesc,
                child: Text('Best Accuracy'),
              ),
              PopupMenuItem(
                value: _SortOption.accuracyAsc,
                child: Text('Worst Accuracy'),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      body: _sessions.isEmpty
          ? const Center(child: Text('История пуста'))
          : ListView.separated(
              itemCount: _sessions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = _sessions[index];
                final s = entry.summary;
                return ListTile(
                  title: Text(
                    formatDateTime(s.date),
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${s.correct}/${s.total} • ${s.accuracy.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  onLongPress: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Delete Session?'),
                          content: const Text(
                            'Are you sure you want to delete this session?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        );
                      },
                    );
                    if (confirm == true) {
                      final service = context
                          .read<CloudTrainingHistoryService>();
                      await service.deleteSession(entry.path);
                      if (mounted) {
                        setState(() => _sessions.removeAt(index));
                      }
                    }
                  },
                );
              },
            ),
    );
  }
}
