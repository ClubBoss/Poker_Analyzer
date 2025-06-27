import 'package:flutter/material.dart';

import '../models/training_spot.dart';
import 'training_review_screen.dart';

class TrainingSpotViewerScreen extends StatelessWidget {
  final TrainingSpot spot;

  const TrainingSpotViewerScreen({super.key, required this.spot});

  @override
  Widget build(BuildContext context) {
    return TrainingReviewScreen(title: 'Спот', spot: spot);
  }
}
