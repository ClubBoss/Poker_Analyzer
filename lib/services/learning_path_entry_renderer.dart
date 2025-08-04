import 'package:flutter/material.dart';

import '../models/theory_mini_lesson_node.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_preview_spot.dart';
import '../models/v2/hero_position.dart';
import '../screens/mini_lesson_screen.dart';
import '../services/training_session_launcher.dart';
import '../widgets/theory_lesson_preview_tile.dart';
import '../widgets/training_pack_preview_card.dart';
import '../widgets/pack_card.dart';

/// Renders individual [LearningPathEntry] items into widgets.
class LearningPathEntryRenderer {
  const LearningPathEntryRenderer();

  /// Builds a widget for a single [entry].
  ///
  /// Supported entry types:
  /// * [TheoryMiniLessonNode] – rendered via [TheoryLessonPreviewTile]
  /// * [TrainingPackSpot] – rendered via [TrainingPackPreviewCard]
  /// * [TrainingPackTemplateV2] – rendered via [PackCard]
  Widget build(BuildContext context, Object entry) {
    if (entry is TheoryMiniLessonNode) {
      return TheoryLessonPreviewTile(
        node: entry,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MiniLessonScreen(lesson: entry),
            ),
          );
        },
      );
    } else if (entry is TrainingPackTemplateV2) {
      return PackCard(
        template: entry,
        onTap: () => const TrainingSessionLauncher().launch(entry),
      );
    } else if (entry is TrainingPackSpot) {
      final preview = TrainingPackPreviewSpot(
        hand: entry.hand.heroCards,
        position: entry.hand.position.label,
        action: entry.correctAction ?? '',
      );
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TrainingPackPreviewCard(spot: preview),
      );
    }
    return const SizedBox.shrink();
  }
}

