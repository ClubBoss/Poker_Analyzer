import 'package:flutter/material.dart';

import '../controllers/training_pack_controller.dart';
import '../widgets/common/training_spot_list_core.dart';

class PackSpotList extends StatelessWidget {
  final TrainingPackController controller;
  final ValueChanged<int> onEdit;
  final Key? listKey;
  const PackSpotList({
    super.key,
    required this.controller,
    required this.onEdit,
    this.listKey,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => TrainingSpotList(
        key: listKey,
        spots: controller.spots,
        onEdit: onEdit,
        onRemove: controller.removeSpot,
        onChanged: controller.saveSpots,
        onReorder: controller.reorder,
      ),
    );
  }
}

