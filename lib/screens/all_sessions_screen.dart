import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/training_pack.dart';

class AllSessionsScreen extends StatefulWidget {
  const AllSessionsScreen({super.key});

  @override
  State<AllSessionsScreen> createState() => _AllSessionsScreenState();
}

class _SessionEntry {
  final String packName;
  final TrainingSessionResult result;
  _SessionEntry(this.packName, this.result);
}

class _AllSessionsScreenState extends State<AllSessionsScreen> {
  final List<_SessionEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  Future<void> _loadHistory() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/training_packs.json');
    if (!await file.exists()) return;
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content);
      if (data is List) {
        final packs = [
          for (final item in data)
            if (item is Map<String, dynamic>)
              TrainingPack.fromJson(Map<String, dynamic>.from(item))
        ];
        final List<_SessionEntry> all = [];
        for (final p in packs) {
          for (final r in p.history) {
            all.add(_SessionEntry(p.name, r));
          }
        }
        all.sort((a, b) => b.result.date.compareTo(a.result.date));
        setState(() => _entries
          ..clear()
          ..addAll(all));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История тренировок'),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      body: _entries.isEmpty
          ? const Center(
              child: Text('История пуста'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final e = _entries[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2B2E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.packName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(e.result.date),
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${e.result.correct}/${e.result.total}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            e.result.total > 0
                                ? '${(e.result.correct * 100 / e.result.total).toStringAsFixed(0)}%'
                                : '0%',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
