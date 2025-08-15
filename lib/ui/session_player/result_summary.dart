import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'answer_log.dart';
import 'models.dart';
import 'review_page.dart';

class ResultSummaryView extends StatelessWidget {
  final List<UiSpot> spots;
  final List<UiAnswer> answers;
  final VoidCallback onReplayErrors;
  final VoidCallback onRestart;

  const ResultSummaryView({
    super.key,
    required this.spots,
    required this.answers,
    required this.onReplayErrors,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final correct = answers.where((a) => a.correct).length;
    final total = answers.length;
    final totalTime =
        answers.fold(Duration.zero, (d, a) => d + a.elapsed);
    final totalSecs = totalTime.inMilliseconds / 1000;
    final avgSecs = total > 0 ? totalSecs / total : 0;
    final percent = total > 0 ? (correct / total * 100).round() : 0;
    final mistakes = <SpotKind, int>{};
    for (var i = 0; i < spots.length; i++) {
      if (!answers[i].correct) {
        final kind = spots[i].kind;
        mistakes[kind] = (mistakes[kind] ?? 0) + 1;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Result: $correct/$total ($percent%)',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Total: ${totalSecs.toStringAsFixed(1)}s • Avg: ${avgSecs.toStringAsFixed(1)}s',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ...mistakes.entries
              .map((e) => Text('${e.key.name}: ${e.value}')),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onReplayErrors,
            child: const Text('Replay errors'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onRestart,
            child: const Text('Restart'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReviewAnswersPage(
                    spots: spots,
                    answers: answers,
                  ),
                ),
              );
            },
            child: const Text('Review answers'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              final json = const JsonEncoder.withIndent('  ')
                  .convert(buildAnswerLog(spots, answers).toJson());
              await Clipboard.setData(ClipboardData(text: json));
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Copied')));
            },
            child: const Text('Export JSON'),
          ),
        ],
      ),
    );
  }
}
