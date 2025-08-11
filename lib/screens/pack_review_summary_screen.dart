import 'package:flutter/material.dart';
import '../models/training_pack.dart';
import '../models/v2/training_pack_template.dart';
import '../services/training_session_launcher.dart';
import '../theme/app_colors.dart';
import '../models/v2/training_pack_template_v2.dart';

class PackReviewSummaryScreen extends StatelessWidget {
  final TrainingPackTemplate template;
  final TrainingSessionResult result;
  final Duration elapsed;
  const PackReviewSummaryScreen({
    super.key,
    required this.template,
    required this.result,
    required this.elapsed,
  });

  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = result.total == 0 ? 0.0 : result.correct * 100 / result.total;
    return Scaffold(
      appBar: AppBar(title: Text(template.name)),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${result.correct} / ${result.total}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Accuracy: ${accuracy.toStringAsFixed(1)}%',
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text('Time: ${_format(elapsed)}',
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: result.tasks.length,
                itemBuilder: (context, index) {
                  final t = result.tasks[index];
                  return ListTile(
                    leading: Icon(
                      t.correct ? Icons.check : Icons.close,
                      color: t.correct ? Colors.green : Colors.red,
                    ),
                    title: Text(t.question,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      'Your: ${t.selectedAnswer} • Correct: ${t.correctAnswer}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  const TrainingSessionLauncher().launch(
                    TrainingPackTemplateV2.fromTemplate(template),
                  );
                },
                child: const Text('Repeat this pack'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to history'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

