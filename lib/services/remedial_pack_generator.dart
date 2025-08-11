import '../models/autogen_preset.dart';
import '../models/texture_filter_config.dart';
import '../models/theory_injector_config.dart';
import '../models/remedial_spec.dart';
import 'learning_path_telemetry.dart';

class RemedialPackGenerator {
  AutogenPreset build(String pathId, String stageId, RemedialSpec spec,
      {int spotsPerPack = 6}) {
    final bounded = spotsPerPack.clamp(6, 12);
    final total = spec.textureCounts.values.fold<int>(0, (a, b) => a + b);
    final mix = <String, double>{};
    if (total > 0) {
      spec.textureCounts.forEach((k, v) {
        final w = v / total;
        mix[k] = w > 0.4 ? 0.4 : double.parse(w.toStringAsFixed(2));
      });
    }
    final textures = TextureFilterConfig(targetMix: mix);
    final theory = const TheoryInjectorConfig(
      enabled: true,
      minScore: 0.7,
      preferNovelty: false,
    );
    final preset = AutogenPreset(
      id: 'remedial_v1',
      name: 'Remedial Pack',
      textures: textures,
      theory: theory,
      spotsPerPack: bounded,
      extras: {
        if (spec.topTags.isNotEmpty) 'boostTags': spec.topTags,
        'stageId': stageId,
      },
    );
    LearningPathTelemetry.instance.log('remedial_created', {
      'pathId': pathId,
      'stageId': stageId,
      'remedialPackId': preset.id,
      'missTags': spec.topTags,
      'missTextures': spec.textureCounts,
    });
    return preset;
  }
}
