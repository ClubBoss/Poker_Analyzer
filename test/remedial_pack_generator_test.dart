import 'package:test/test.dart';
import 'package:poker_analyzer/services/remedial_pack_generator.dart';
import 'package:poker_analyzer/models/remedial_spec.dart';

void main() {
  test('generator produces preset with bounded spot count and target mix', () {
    final spec = RemedialSpec(
      topTags: ['a'],
      textureCounts: {'monotone': 3, 'paired': 2},
      streetBias: 1,
      minAccuracyTarget: 0.7,
    );
    final gen = RemedialPackGenerator();
    final preset = gen.build('path1', 'stage1', spec, spotsPerPack: 20);
    expect(preset.spotsPerPack, 12);
    expect(preset.textures.targetMix.values.every((v) => v <= 0.4), true);
    expect(preset.theory.enabled, true);
    expect(preset.theory.preferNovelty, false);
  });
}
