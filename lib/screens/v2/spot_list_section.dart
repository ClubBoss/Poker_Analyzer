import 'package:flutter/material.dart';

import '../../models/v2/training_pack_spot.dart';

/// Displays a list of spots inside a training pack template.
///
/// This widget is intentionally small and focused purely on the
/// list presentation.  Any filtering or editing logic can live in
/// higher level widgets or services.
class SpotListSection extends StatelessWidget {
  final List<TrainingPackSpot> spots;
  final ValueChanged<TrainingPackSpot> onSelected;
  final String? selectedId;

  const SpotListSection({
    super.key,
    required this.spots,
    required this.onSelected,
    this.selectedId,
  });

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) {
      return const Center(child: Text('No spots in template'));
    }
    return ListView.builder(
      itemCount: spots.length,
      itemBuilder: (context, index) {
        final spot = spots[index];
        final selected = spot.id == selectedId;
        return ListTile(
          selected: selected,
          title: Text(spot.hand.heroCards),
          subtitle: Text(spot.hand.position.label),
          onTap: () => onSelected(spot),
        );
      },
    );
  }
}
