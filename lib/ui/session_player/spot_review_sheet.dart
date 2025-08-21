import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';

class SpotReviewSheet extends StatelessWidget {
  final int index; // 1-based index to display
  final UiSpot spot;
  final UiAnswer answer;

  const SpotReviewSheet({
    super.key,
    required this.index,
    required this.spot,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    final ok = answer.correct;
    final icon = ok ? Icons.check_circle : Icons.cancel;
    final color = ok ? Colors.green : Colors.red;

    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Text(k,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(v)),
            ],
          ),
        );

    return SafeArea(
      child: Padding(
        padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Spot $index - ${spot.hand}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy row JSON',
                  onPressed: () async {
                    final m = {
                      'i': index,
                      'hand': spot.hand,
                      'pos': spot.pos,
                      'vsPos': spot.vsPos,
                      'stack': spot.stack,
                      'expected': answer.expected,
                      'chosen': answer.chosen,
                      'correct': answer.correct,
                      'elapsed_ms': answer.elapsed.inMilliseconds,
                      'explain': spot.explain,
                    };
                    final json = const JsonEncoder.withIndent('  ').convert(m);
                    await Clipboard.setData(ClipboardData(text: json));
                    try {
                      HapticFeedback.selectionClick();
                    } catch (_) {}
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('Copied')));
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            row(
              'Pos',
              spot.pos + (spot.vsPos != null ? ' vs ${spot.vsPos}' : ''),
            ),
            row('Stack', spot.stack),
            row('Expected', answer.expected),
            row('Chosen', answer.chosen),
            row('Elapsed', '${answer.elapsed.inMilliseconds} ms'),
            const SizedBox(height: 8),
            if (spot.explain != null && spot.explain!.trim().isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black12),
                ),
                child: Text(spot.explain!),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
