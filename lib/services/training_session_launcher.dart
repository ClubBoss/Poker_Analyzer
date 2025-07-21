import 'package:flutter/material.dart';

import '../main.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_v2.dart';
import '../screens/training_session_screen.dart';

/// Helper to start a training session from a pack template.
class TrainingSessionLauncher {
  const TrainingSessionLauncher();

  /// Launches a training session for [template].
  Future<void> launch(TrainingPackTemplateV2 template) async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    final pack = TrainingPackV2.fromTemplate(template, template.id);
    await Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => TrainingSessionScreen(pack: pack)),
    );
  }
}
