import '../models/v2/training_pack_spot.dart';
import 'skill_tag_skill_node_map_service.dart';

/// Links spots to skill tree nodes based on their tags.
class SkillTreeAutoLinker {
  final SkillTagSkillNodeMapService map;

  const SkillTreeAutoLinker({SkillTagSkillNodeMapService? map})
    : map = map ?? const SkillTagSkillNodeMapService();

  /// Assigns `skillNode` meta fields for all [spots].
  void linkAll(List<TrainingPackSpot> spots) {
    final used = <String>{};
    for (final s in spots) {
      for (final tag in s.tags) {
        final node = map.nodeIdForTag(tag);
        if (node != null && used.add(node)) {
          s.meta['skillNode'] = node;
          break;
        }
      }
    }
  }
}
