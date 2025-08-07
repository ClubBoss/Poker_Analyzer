import '../models/v2/training_pack_spot.dart';
import '../models/autogen_status.dart';
import 'skill_tag_skill_node_map_service.dart';
import 'autogen_status_dashboard_service.dart';

/// Links spots to skill tree nodes based on their tags.
class SkillTreeAutoLinker {
  final SkillTagSkillNodeMapService map;

  const SkillTreeAutoLinker({SkillTagSkillNodeMapService? map})
    : map = map ?? const SkillTagSkillNodeMapService();

  /// Assigns `skillNode` meta fields for all [spots].
  void linkAll(List<TrainingPackSpot> spots) {
    final status = AutogenStatusDashboardService.instance;
    status.update(
      'SkillTreeAutoLinker',
      const AutogenStatus(
        isRunning: true,
        currentStage: 'link',
        progress: 0,
      ),
    );
    try {
      final used = <String>{};
      for (var i = 0; i < spots.length; i++) {
        final s = spots[i];
        for (final tag in s.tags) {
          final node = map.nodeIdForTag(tag);
          if (node != null && used.add(node)) {
            s.meta['skillNode'] = node;
            break;
          }
        }
        status.update(
          'SkillTreeAutoLinker',
          AutogenStatus(
            isRunning: true,
            currentStage: 'link',
            progress: (i + 1) / spots.length,
          ),
        );
      }
      status.update(
        'SkillTreeAutoLinker',
        const AutogenStatus(
          isRunning: false,
          currentStage: 'complete',
          progress: 1,
        ),
      );
    } catch (e) {
      status.update(
        'SkillTreeAutoLinker',
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
