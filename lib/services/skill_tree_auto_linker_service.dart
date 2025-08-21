import '../models/training_pack_model.dart';
import '../models/theory_mini_lesson_node.dart';
import '../models/autogen_status.dart';
import 'autogen_status_dashboard_service.dart';

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

  SkillLinkResult({List<String>? packIds, List<String>? lessonIds})
      : packIds = packIds ?? const [],
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
    final status = AutogenStatusDashboardService.instance;
    status.update(
      'SkillTreeAutoLinkerService',
      const AutogenStatus(isRunning: true, currentStage: 'link', progress: 0),
    );
    try {
      final res = <String, SkillLinkResult>{};
      for (var i = 0; i < nodes.length; i++) {
        final node = nodes[i];
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
        status.update(
          'SkillTreeAutoLinkerService',
          AutogenStatus(
            isRunning: true,
            currentStage: 'link',
            progress: (i + 1) / nodes.length,
          ),
        );
      }
      status.update(
        'SkillTreeAutoLinkerService',
        const AutogenStatus(
          isRunning: false,
          currentStage: 'complete',
          progress: 1,
        ),
      );
      return res;
    } catch (e) {
      status.update(
        'SkillTreeAutoLinkerService',
        AutogenStatus(
          isRunning: false,
          currentStage: 'error',
          progress: 0,
          lastError: e.toString(),
        ),
      );
      rethrow;
    }
  }
}
