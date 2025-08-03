import 'package:flutter/material.dart';

import '../controllers/training_pack_controller.dart';
import '../widgets/common/training_spot_list_core.dart';

class TrainingPackSpotPanel extends StatelessWidget {
  final TrainingPackController controller;
  final GlobalKey<TrainingSpotListState>? listKey;

  const TrainingPackSpotPanel({
    super.key,
    required this.controller,
    this.listKey,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => TrainingSpotList(
        key: listKey,
        spots: controller.spots,
        onRemove: controller.removeSpot,
        onChanged: controller.saveSpots,
        onReorder: controller.reorder,
      ),
    );
  }
}

