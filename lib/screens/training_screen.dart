import 'package:flutter/material.dart';

import '../models/training_spot.dart';
import '../widgets/training_spot_diagram.dart';
import '../widgets/training_spot_preview.dart';

/// Simple screen that shows a single [TrainingSpot].
class TrainingScreen extends StatelessWidget {
  final TrainingSpot spot;

  const TrainingScreen({super.key, required this.spot});

  @override
  Widget build(BuildContext context) {
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
            TrainingSpotPreview(spot: spot),
          ],
        ),
      ),
    );
  }
}
