import 'package:flutter/material.dart';

import '../models/training_spot.dart';
import '../widgets/training_spot_diagram.dart';
import '../widgets/training_spot_preview.dart';
import '../widgets/replay_spot_widget.dart';

/// Simple screen that shows a single [TrainingSpot].
class TrainingScreen extends StatefulWidget {
  final TrainingSpot spot;

  const TrainingScreen({super.key, required this.spot});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  String? _selected;

  void _choose(String action) {
    if (_selected != null) return;
    setState(() => _selected = action);
  }

  void _reset() => setState(() => _selected = null);

  @override
  Widget build(BuildContext context) {
    final spot = widget.spot;
    final expected = spot.strategyAdvice != null &&
            spot.heroIndex < spot.strategyAdvice!.length
        ? spot.strategyAdvice![spot.heroIndex].toUpperCase()
        : null;
    final isCorrect =
        _selected != null && expected != null && _selected == expected;

    double? ev;
    if (spot.equities != null && spot.heroIndex < spot.equities!.length) {
      ev = spot.equities![spot.heroIndex].toDouble();
    }

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
            if (_selected == null) ...[
              const Text(
                'Your action?',
                style: TextStyle(color: Colors.white70),
              ),
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
                isCorrect ? 'Correct!' : 'Incorrect. Expected $expected',
                style: TextStyle(
                  color: isCorrect ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (ev != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'EV: ${ev.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _reset,
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
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (_) => ReplaySpotWidget(spot: spot),
                      );
                    },
                    child: const Text('Replay Hand'),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            TrainingSpotPreview(spot: spot),
          ],
        ),
      ),
    );
  }
}
