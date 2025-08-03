import 'package:flutter/material.dart';
import '../../models/training_spot.dart';

class TrainingSpotOverlay extends StatelessWidget {
  final Widget child;
  final void Function(List<TrainingSpot> spots)? onSpotsDropped;

  const TrainingSpotOverlay({
    super.key,
    required this.child,
    this.onSpotsDropped,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<List<TrainingSpot>>(
      onAccept: onSpotsDropped,
      builder: (context, _, __) => child,
    );
  }
}
