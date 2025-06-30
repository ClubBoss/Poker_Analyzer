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
    final hero = spot.hand.heroCards;
    final pos = spot.hand.position;
    final pre = spot.hand.actions[0];
    final first = pre.isEmpty ? null : pre.first.customLabel ?? pre.first.action;
    final act = first == null
        ? null
        : (first.length > 40 ? first.substring(0, 40) : first);
    final legacy = hero.isEmpty && spot.note.trim().isNotEmpty;
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
          if (hero.isNotEmpty || pos.isNotEmpty || legacy)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                legacy ? '(legacy)' : '$hero $pos'.trim(),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          if (act != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                act,
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
