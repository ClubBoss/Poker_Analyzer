import 'package:flutter/material.dart';
import '../../models/v2/training_pack_spot.dart';

class TrainingPackSpotPreviewCard extends StatelessWidget {
  final TrainingPackSpot spot;
  const TrainingPackSpotPreviewCard({super.key, required this.spot});

  @override
  Widget build(BuildContext context) {
    final note = spot.note.trim();
    final first = note.isEmpty ? null : note.split('\n').first;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              spot.title.isEmpty ? 'Untitled spot' : spot.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (first != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  first,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
