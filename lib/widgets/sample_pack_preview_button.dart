import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/training_pack_sampler.dart';
import '../core/training/engine/training_type_engine.dart';
import '../services/training_session_service.dart';
import '../screens/training_session_screen.dart';

/// Button to quickly preview a sampled version of a training pack.
class SamplePackPreviewButton extends StatelessWidget {
  final TrainingPackTemplate template;
  final bool locked;
  final int maxSpots;

  const SamplePackPreviewButton({
    super.key,
    required this.template,
    required this.locked,
    this.maxSpots = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (template.spots.length <= 30) {
      return const SizedBox.shrink();
    }
    return Tooltip(
      message: 'Fast preview of sample spots',
      child: TextButton(
        onPressed: locked
            ? null
            : () async {
                final sampler = const TrainingPackSampler();
                final tplV2 = TrainingPackTemplateV2.fromTemplate(
                  template,
                  type: const TrainingTypeEngine().detectTrainingType(template),
                );
                final sample = sampler.sample(tplV2, maxSpots: maxSpots);
                final preview = TrainingPackTemplate.fromJson(sample.toJson());
                preview.meta['samplePreview'] = true;
                await context
                    .read<TrainingSessionService>()
                    .startSession(preview, persist: false);
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TrainingSessionScreen()),
                );
              },
        child: const Text('👁 Preview Sample'),
      ),
    );
  }
}
