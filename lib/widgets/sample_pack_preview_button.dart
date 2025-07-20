import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/training_pack_template.dart';
import '../models/v2/training_pack_template.dart' as v2;
import '../models/v2/training_pack_template_v2.dart';
import '../services/training_pack_sampler.dart';
import '../services/training_session_service.dart';
import '../screens/v2/training_pack_play_screen.dart';

class SamplePackPreviewButton extends StatelessWidget {
  final TrainingPackTemplate template;
  final int maxSpots;

  const SamplePackPreviewButton({
    super.key,
    required this.template,
    this.maxSpots = 15,
  });

  @override
  Widget build(BuildContext context) {
    if (template.spots.length <= 30) return const SizedBox.shrink();

    return Tooltip(
      message: 'Preview $maxSpots random spots',
      child: OutlinedButton(
        onPressed: () async {
          final sampler = const TrainingPackSampler();
          final tplV2 = TrainingPackTemplateV2.fromJson(template.toJson());
          final sampledV2 = sampler.sample(tplV2, maxSpots: maxSpots);
          final sampled = v2.TrainingPackTemplate.fromJson(sampledV2.toJson())
            ..meta['sampledPack'] = true;
          final original = v2.TrainingPackTemplate.fromJson(template.toJson());
          await context
              .read<TrainingSessionService>()
              .startSession(sampled, persist: false);
          if (context.mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    TrainingPackPlayScreen(template: sampled, original: original),
              ),
            );
          }
        },
        child: const Text('👁 Preview Sample'),
      ),
    );
  }
}
