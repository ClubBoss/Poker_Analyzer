import 'package:flutter/material.dart';

class TrainingSpotFilterPanel extends StatelessWidget {
  final Set<String> tags;
  final Set<String> positions;
  final String positionValue;
  final String tagValue;
  final ValueChanged<String?> onPositionChanged;
  final ValueChanged<String?> onTagChanged;

  const TrainingSpotFilterPanel({
    super.key,
    required this.tags,
    required this.positions,
    required this.positionValue,
    required this.tagValue,
    required this.onPositionChanged,
    required this.onTagChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          DropdownButton<String>(
            value: positionValue,
            underline: const SizedBox.shrink(),
            onChanged: onPositionChanged,
            items: ['All', ...positions]
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: tagValue,
            underline: const SizedBox.shrink(),
            onChanged: onTagChanged,
            items: ['All', ...tags]
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
          ),
        ],
      ),
    );
  }
}
