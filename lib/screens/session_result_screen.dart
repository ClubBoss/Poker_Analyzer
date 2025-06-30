import 'package:flutter/material.dart';

class SessionResultScreen extends StatelessWidget {
  final int total;
  final int correct;
  final Duration elapsed;
  const SessionResultScreen({super.key, required this.total, required this.correct, required this.elapsed});

  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final rate = total == 0 ? 0 : correct * 100 / total;
    return Scaffold(
      appBar: AppBar(title: const Text('Session Result')),
      backgroundColor: const Color(0xFF1B1C1E),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$correct / $total',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Accuracy: ${rate.toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('Time: ${_format(elapsed)}',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
