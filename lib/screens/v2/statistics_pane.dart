import 'package:flutter/material.dart';

import '../../models/v2/training_pack_template.dart';

/// Small widget that shows basic information about the template.
/// For now it only displays spot count but can be extended with
/// more advanced statistics in the future.
class StatisticsPane extends StatelessWidget {
  final TrainingPackTemplate template;
  const StatisticsPane({super.key, required this.template});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spots: ${template.spots.length}',
              style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
