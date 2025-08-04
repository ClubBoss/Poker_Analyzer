import '../../models/v2/training_pack_spot.dart';

class TheorySpotFactory {
  const TheorySpotFactory();

  TrainingPackSpot fromYaml(Map yaml) {
    return TrainingPackSpot(
      id: yaml['id']?.toString() ?? '',
      type: 'theory',
      title: yaml['title']?.toString() ?? '',
      explanation: yaml['explanation']?.toString() ?? '',
      tags: [for (final t in (yaml['tags'] as List? ?? [])) t.toString()],
    );
  }
}
