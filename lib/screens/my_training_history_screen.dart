import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/date_utils.dart';
import '../models/session_summary.dart';
import '../models/training_pack.dart';
import '../services/training_pack_storage_service.dart';
import 'training_pack_screen.dart';
import '../widgets/sync_status_widget.dart';

class MyTrainingHistoryScreen extends StatefulWidget {
  const MyTrainingHistoryScreen({super.key});

  @override
  State<MyTrainingHistoryScreen> createState() =>
      _MyTrainingHistoryScreenState();
}

class _HistoryEntry {
  final TrainingPack pack;
  final SessionSummary summary;

  _HistoryEntry(this.pack, this.summary);
}

class _MyTrainingHistoryScreenState extends State<MyTrainingHistoryScreen> {
  final List<_HistoryEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final packs = context.read<TrainingPackStorageService>().packs;
    final List<_HistoryEntry> loaded = [];
    for (final pack in packs) {
      final key = 'results_${pack.name}';
      final jsonStr = prefs.getString(key);
      if (jsonStr == null) continue;
      try {
        final data = jsonDecode(jsonStr);
        if (data is Map && data['history'] is List) {
          final history = data['history'] as List;
          for (final item in history.take(5)) {
            if (item is Map) {
              final summary =
                  SessionSummary.fromJson(Map<String, dynamic>.from(item));
              loaded.add(_HistoryEntry(pack, summary));
            }
          }
        }
      } catch (_) {}
    }
    loaded.sort((a, b) => b.summary.date.compareTo(a.summary.date));
    setState(() {
      _entries
        ..clear()
        ..addAll(loaded);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои тренировки'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      body: _entries.isEmpty
          ? const Center(child: Text('История пуста'))
          : ListView.separated(
              itemCount: _entries.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final entry = _entries[index];
                final summary = entry.summary;
                return ListTile(
                  title: Text(
                    entry.pack.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${formatDateTime(summary.date)} \u2022 ${summary.correct}/${summary.total} \u2022 ${summary.accuracy.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TrainingPackScreen(pack: entry.pack),
                        ),
                      );
                    },
                    child: const Text('Открыть'),
                  ),
                );
              },
            ),
    );
  }
}
