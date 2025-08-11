import 'pack_spec.dart';

class RemedialSpec implements PackSpec {
  @override
  final List<String> topTags;
  @override
  final Map<String, int> textureCounts;
  @override
  final int streetBias;
  @override
  final double minAccuracyTarget;

  const RemedialSpec({
    this.topTags = const [],
    this.textureCounts = const {},
    this.streetBias = 0,
    this.minAccuracyTarget = 0,
  });
}
