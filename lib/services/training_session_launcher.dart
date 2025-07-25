import 'package:flutter/material.dart';

import '../main.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_v2.dart';
import '../screens/training_session_screen.dart';
import '../screens/theory_pack_preview_screen.dart';
import 'achievements_engine.dart';
import 'dart:async';

/// Helper to start a training session from a pack template.
class TrainingSessionLauncher {
  const TrainingSessionLauncher();

  /// Launches a training session for [template]. If the pack only contains
  /// theory spots, shows [TheoryPackPreviewScreen] first.
  Future<void> launch(TrainingPackTemplateV2 template, {int startIndex = 0}) async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    if (template.spots.every((s) => s.type == 'theory')) {
      await Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) => TheoryPackPreviewScreen(template: template),
        ),
      );
      unawaited(AchievementsEngine.instance.checkAll());
      return;
    }

    final pack = TrainingPackV2.fromTemplate(template, template.id);
    await Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => TrainingSessionScreen(
          pack: pack,
          startIndex: startIndex,
        ),
      ),
    );
    unawaited(AchievementsEngine.instance.checkAll());
  }
}
