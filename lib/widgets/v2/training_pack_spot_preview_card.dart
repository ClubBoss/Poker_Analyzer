import 'package:flutter/material.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../screens/v2/hand_editor_screen.dart';

class TrainingPackSpotPreviewCard extends StatelessWidget {
  final TrainingPackSpot spot;
  final VoidCallback? onHandEdited;
  final ValueChanged<String>? onTagTap;
  const TrainingPackSpotPreviewCard({
    super.key,
    required this.spot,
    this.onHandEdited,
    this.onTagTap,
  });

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
          if (spot.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                children: [
                  for (final tag in spot.tags)
                    InputChip(
                      label: Text(tag, style: const TextStyle(fontSize: 12)),
                      onPressed: () => onTagTap?.call(tag.toLowerCase()),
                    ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => HandEditorScreen(spot: spot)),
                  );
                  onHandEdited?.call();
                },
                child: const Text('✏️ Edit Hand'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  }
}
