import 'package:flutter/material.dart';

import '../controllers/learning_path_controller.dart';
import '../models/learning_path_stage_model.dart';

/// Minimal pack run screen that records hands and shows progress.
class PackRunScreen extends StatefulWidget {
  final LearningPathController controller;
  final LearningPathStageModel stage;
  const PackRunScreen({super.key, required this.controller, required this.stage});

  @override
  State<PackRunScreen> createState() => _PackRunScreenState();
}

class _PackRunScreenState extends State<PackRunScreen> {
  @override
  Widget build(BuildContext context) {
    final progress = widget.controller.stageProgress(widget.stage.id);
    final requiredHands = widget.stage.requiredHands;
    final requiredAcc = widget.stage.requiredAccuracy * 100;
    return Scaffold(
      appBar: AppBar(title: Text(widget.stage.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Hands: ' + progress.handsPlayed.toString() + '/' + requiredHands.toString()),
            Text('Accuracy: ' + (progress.accuracy * 100).toStringAsFixed(0) + '% / ' + requiredAcc.toStringAsFixed(0) + '%'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                widget.controller.recordHand(correct: true);
                setState(() {});
              },
              child: const Text('Record Correct'),
            ),
            ElevatedButton(
              onPressed: () {
                widget.controller.recordHand(correct: false);
                setState(() {});
              },
              child: const Text('Record Incorrect'),
            ),
            if (widget.controller.stageProgress(widget.stage.id).completed)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Stage complete!'),
              ),
          ],
        ),
      ),
    );
  }
}

