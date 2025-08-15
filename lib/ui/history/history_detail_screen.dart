import 'package:flutter/material.dart';

class HistoryDetailScreen extends StatelessWidget {
  const HistoryDetailScreen({super.key, required this.entry});

  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final acc = (entry['acc'] ?? 0) as num;
    final correct = entry['correct'] ?? 0;
    final total = entry['total'] ?? 0;
    final ts = entry['ts']?.toString() ?? '';
    final dt = DateTime.tryParse(ts)?.toLocal();
    final dateStr = dt?.toString() ?? ts;

    void showNotAvailable() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not available (v1)')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Session')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: const Text('Date'),
            subtitle: Text(dateStr),
          ),
          ListTile(
            title: const Text('Accuracy'),
            subtitle: Text('${(acc * 100).toStringAsFixed(0)}%'),
          ),
          ListTile(
            title: const Text('Correct / Total'),
            subtitle: Text('$correct / $total'),
          ),
          const Spacer(),
          ButtonBar(
            alignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: total == 0 ? null : showNotAvailable,
                child: const Text('Replay errors'),
              ),
              ElevatedButton(
                onPressed: total == 0 ? null : showNotAvailable,
                child: const Text('Replay all'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
