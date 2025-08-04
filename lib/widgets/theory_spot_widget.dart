import 'package:flutter/material.dart';
import '../models/v2/training_pack_spot.dart';

/// Displays theory content within a training session with optional
/// navigation to adjacent theory spots.
class TheorySpotWidget extends StatelessWidget {
  /// All spots of the current training pack.
  final List<TrainingPackSpot> spots;

  /// Index of the spot to display.
  final int index;

  const TheorySpotWidget({
    super.key,
    required this.spots,
    required this.index,
  });

  TrainingPackSpot get _spot => spots[index];

  int? _previousIndex() {
    for (int i = index - 1; i >= 0; i--) {
      if (spots[i].type == 'theory') return i;
    }
    return null;
  }

  int? _nextIndex() {
    for (int i = index + 1; i < spots.length; i++) {
      if (spots[i].type == 'theory') return i;
    }
    return null;
  }

  void _openSpot(BuildContext context, int idx) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TheorySpotWidget(spots: spots, index: idx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prev = _previousIndex();
    final next = _nextIndex();
    return Scaffold(
      appBar: AppBar(title: Text(_spot.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _spot.explanation ?? '',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (prev != null)
              ElevatedButton(
                onPressed: () => _openSpot(context, prev),
                child: const Text('Назад'),
              )
            else
              const SizedBox(width: 0, height: 0),
            ElevatedButton(
              onPressed: () {
                if (next != null) {
                  _openSpot(context, next);
                } else {
                  Navigator.pop(context, index);
                }
              },
              child: Text(next != null ? 'Далее' : 'Закрыть'),
            ),
          ],
        ),
      ),
    );
  }
}
