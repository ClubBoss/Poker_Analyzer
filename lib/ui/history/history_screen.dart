import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'history_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final file = File('out/sessions_history.jsonl');
      if (await file.exists()) {
        final lines = await file.readAsLines();
        final entries = <Map<String, dynamic>>[];
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          try {
            final obj = jsonDecode(line);
            if (obj is Map<String, dynamic>) entries.add(obj);
          } catch (_) {}
        }
        setState(() {
          _items = entries.reversed.take(20).toList();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final e = _items[index];
          final dt = DateTime.tryParse(e['ts']?.toString() ?? '')?.toLocal();
          final dateStr = dt?.toString() ?? e['ts']?.toString() ?? '';
          final acc = (e['acc'] ?? 0) as num;
          final correct = e['correct'] ?? 0;
          final total = e['total'] ?? 0;
          return ListTile(
            title: Text(dateStr),
            subtitle: Text('$correct/$total (${(acc * 100).toStringAsFixed(0)}%)'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => HistoryDetailScreen(entry: e),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
