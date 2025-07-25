import 'package:flutter/material.dart';
import '../models/v2/training_pack_spot.dart';

class TheorySpotWidget extends StatelessWidget {
  final TrainingPackSpot spot;
  const TheorySpotWidget({super.key, required this.spot});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(spot.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            spot.explanation ?? '',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
