import 'package:flutter/material.dart';

import '../core/training/engine/training_type_engine.dart';

class TagMatrixCoverageFilters extends StatelessWidget {
  final TrainingType? type;
  final bool starter;
  final ValueChanged<TrainingType?> onTypeChanged;
  final ValueChanged<bool> onStarterChanged;

  const TagMatrixCoverageFilters({
    super.key,
    required this.type,
    required this.starter,
    required this.onTypeChanged,
    required this.onStarterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      DropdownButton<TrainingType?>(
        value: type,
        hint: const Text('All'),
        onChanged: onTypeChanged,
        items: [
          const DropdownMenuItem(value: null, child: Text('All')),
          ...[
            for (final t in TrainingType.values)
              DropdownMenuItem(value: t, child: Text(t.name))
          ]
        ],
      ),
      const SizedBox(width: 16),
      Row(children: [
        Checkbox(
          value: starter,
          onChanged: (v) => onStarterChanged(v ?? false),
        ),
        const Text('starter'),
      ])
    ]);
  }
}
