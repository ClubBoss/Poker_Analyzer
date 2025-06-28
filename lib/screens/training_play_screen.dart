import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/evaluation_result.dart';
import '../services/training_session_controller.dart';
import '../widgets/training_spot_diagram.dart';
import '../widgets/replay_spot_widget.dart';

class TrainingPlayScreen extends StatefulWidget {
  const TrainingPlayScreen({super.key});

  @override
  State<TrainingPlayScreen> createState() => _TrainingPlayScreenState();
}

class _TrainingPlayScreenState extends State<TrainingPlayScreen> {
  EvaluationResult? _result;

  Future<void> _choose(String action) async {
    final controller = context.read<TrainingSessionController>();
    final spot = controller.currentSpot!;
    final res = await controller.evaluateSpot(context, spot, action);
    setState(() => _result = res);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrainingSessionController>();
    final spot = controller.currentSpot!;
    final correct = _result?.correct ?? false;
    final expected = _result?.expectedAction;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training'),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TrainingSpotDiagram(
              spot: spot,
              size: MediaQuery.of(context).size.width - 32,
            ),
            const SizedBox(height: 16),
            if (_result == null) ...[
              const Text('Ваше действие?',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _choose('PUSH'),
                    child: const Text('PUSH'),
                  ),
                  ElevatedButton(
                    onPressed: () => _choose('FOLD'),
                    child: const Text('FOLD'),
                  ),
                ],
              ),
            ] else ...[
              Text(
                correct ? 'Верно!' : 'Неверно. Надо $expected',
                style: TextStyle(
                  color: correct ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => setState(() => _result = null),
                child: const Text('Try Again'),
              ),
              if (spot.actions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.grey[900],
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (_) => ReplaySpotWidget(spot: spot),
                      );
                    },
                    child: const Text('Replay Hand'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
