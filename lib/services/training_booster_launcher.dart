import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../main.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_spot_v2.dart';
import '../core/training/engine/training_type_engine.dart';
import '../screens/training_session_screen.dart';
import 'training_session_service.dart';

/// Launches an ad-hoc booster pack built from training spots.
class TrainingBoosterLauncher {
  const TrainingBoosterLauncher();

  /// Starts a training session for [spots] if the list is not empty.
  Future<void> launch(List<TrainingSpotV2> spots) async {
    if (spots.isEmpty) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    final tpl = TrainingPackTemplateV2(
      id: const Uuid().v4(),
      name: 'Decay Booster',
      tags: const ['booster', 'decay'],
      trainingType: TrainingType.pushFold,
      spots: spots,
      spotCount: spots.length,
    );
    await ctx.read<TrainingSessionService>().startSession(tpl, persist: false);
    await Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
    );
  }
}
