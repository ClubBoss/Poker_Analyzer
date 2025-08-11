import 'package:flutter/material.dart';

import 'skill_tree_motivational_hint_engine.dart';
import 'skill_tree_progress_analytics_service.dart';
import '../widgets/skill_tree_milestone_overlay.dart';

/// Listens for motivational events and displays celebration overlays.
class SkillTreeMilestoneOverlayService {
  final SkillTreeMotivationalHintEngine engine;

  SkillTreeMilestoneOverlayService({SkillTreeMotivationalHintEngine? engine})
      : engine = engine ?? SkillTreeMotivationalHintEngine.instance;

  OverlayEntry? _entry;

  bool get isShowing => _entry != null;

  /// Checks [stats] and shows an overlay if a milestone message is returned.
  Future<void> maybeShow(
    BuildContext context,
    SkillTreeProgressStats stats,
  ) async {
    if (isShowing) return;
    final message = await engine.getMotivationalMessage(stats);
    if (message == null) return;
    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => SkillTreeMilestoneOverlay(
        message: message,
        onClose: () {
          entry.remove();
          _entry = null;
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }
}
