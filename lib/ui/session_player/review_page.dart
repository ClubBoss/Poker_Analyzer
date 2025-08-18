import 'package:flutter/material.dart';

import 'models.dart';

class ReviewAnswersPage extends StatelessWidget {
  final List<UiSpot> spots;
  final List<UiAnswer> answers;

  const ReviewAnswersPage({
    super.key,
    required this.spots,
    required this.answers,
  });

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: ListView.builder(
        itemCount: answers.length,
        itemBuilder: (context, i) {
          final spot = spots[i];
          final answer = answers[i];
          final t = answer.elapsed.inMilliseconds / 1000;
          return ListTile(
            leading: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: answer.correct ? Colors.green : Colors.red,
              ),
            ),
            title: Text('${spot.hand} • ${spot.pos} • ${spot.stack}'),
            subtitle: Text(
              'expected: ${answer.expected} • chosen: ${answer.chosen} • t=${t.toStringAsFixed(1)}s',
            ),
          );
        },
      ),
    );
  }
}
