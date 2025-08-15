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

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('This will delete all saved sessions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _clear();
    }
  }

  Future<void> _clear() async {
    try {
      final file = File('out/sessions_history.jsonl');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
    setState(() {
      _items = [];
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('History cleared')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _items.length;
    var total = 0;
    var correct = 0;
    for (final e in _items) {
      final t = int.tryParse(e['total']?.toString() ?? '') ?? 0;
      final c = int.tryParse(e['correct']?.toString() ?? '') ?? 0;
      total += t;
      correct += c;
    }
    final acc = total == 0 ? 0 : correct / total;
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmClear,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sessions: $sessions'),
                    Text(
                        'Hands: $correct/$total  •  Acc: ${(acc * 100).toStringAsFixed(0)}%'),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final e = _items[index];
                final dt =
                    DateTime.tryParse(e['ts']?.toString() ?? '')?.toLocal();
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
          ),
        ],
      ),
    );
  }
}
