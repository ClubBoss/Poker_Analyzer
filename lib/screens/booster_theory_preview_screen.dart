import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/learning_path_stage_library.dart';
import '../models/stage_type.dart';
import '../theme/app_colors.dart';

class BoosterTheoryPreviewScreen extends StatelessWidget {
  const BoosterTheoryPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    final stages =
        LearningPathStageLibrary.instance.stages
            .where((s) => s.type == StageType.theory)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      appBar: AppBar(title: const Text('Theory Stages Preview')),
      backgroundColor: AppColors.background,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stages.length,
        itemBuilder: (_, i) {
          final stage = stages[i];
          return ExpansionTile(
            title: Text(stage.title),
            subtitle: Text(stage.packId),
            trailing: Text('${stage.subStages.length} саб-стадии'),
            childrenPadding: const EdgeInsets.only(left: 16, bottom: 8),
            children: [
              for (final sub in stage.subStages)
                ListTile(
                  dense: true,
                  title: Text(sub.title),
                  subtitle: Text(sub.packId),
                ),
            ],
          );
        },
      ),
    );
  }
}
