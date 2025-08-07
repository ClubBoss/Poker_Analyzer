import '../models/training_pack_model.dart';
import '../models/theory_mini_lesson_node.dart';

/// Simple representation of a skill tree node with tag metadata.
class SkillTreeNode {
  final String id;
  final List<String> tags;
  final Map<String, dynamic> meta;

  SkillTreeNode({
    required this.id,
    List<String>? tags,
    Map<String, dynamic>? meta,
  })  : tags = tags ?? const [],
        meta = meta ?? <String, dynamic>{};
}

/// Result of linking a skill node to related packs and lessons.
class SkillLinkResult {
  final List<String> packIds;
  final List<String> lessonIds;

  SkillLinkResult({
    List<String>? packIds,
    List<String>? lessonIds,
  })  : packIds = packIds ?? const [],
        lessonIds = lessonIds ?? const [];
}

/// Service linking skill tree nodes to packs and theory lessons based on tags.
class SkillTreeAutoLinkerService {
  const SkillTreeAutoLinkerService();

  /// Returns mapping from node id to [SkillLinkResult].
  Map<String, SkillLinkResult> link(
    List<SkillTreeNode> nodes,
    List<TrainingPackModel> packs,
    List<TheoryMiniLessonNode> lessons,
  ) {
    final res = <String, SkillLinkResult>{};
    for (final node in nodes) {
      final nodeTags = node.tags.map((t) => t.toLowerCase().trim()).toSet();
      final pIds = <String>[];
      for (final pack in packs) {
        final packTags = <String>{
          for (final spot in pack.spots)
            for (final t in spot.tags) t.toLowerCase().trim(),
          for (final t in pack.tags) t.toLowerCase().trim(),
        };
        if (packTags.intersection(nodeTags).isNotEmpty) {
          pIds.add(pack.id);
        }
      }
      final lIds = <String>[
        for (final lesson in lessons)
          if (lesson.tags
              .map((t) => t.toLowerCase().trim())
              .toSet()
              .intersection(nodeTags)
              .isNotEmpty)
            lesson.id,
      ];
      node.meta['linkedPackIds'] = pIds;
      node.meta['linkedLessonIds'] = lIds;
      res[node.id] = SkillLinkResult(packIds: pIds, lessonIds: lIds);
    }
    return res;
  }
}
