import 'package:flutter/material.dart';
import '../models/v2/training_pack_preview_spot.dart';
import '../theme/app_colors.dart';

class TrainingPackPreviewCard extends StatelessWidget {
  final TrainingPackPreviewSpot spot;
  const TrainingPackPreviewCard({super.key, required this.spot});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(spot.position.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(spot.hand, style: const TextStyle(fontFamily: 'monospace')),
          Text(spot.action, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
