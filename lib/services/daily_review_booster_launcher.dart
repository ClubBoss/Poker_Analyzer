import 'package:flutter/material.dart';

import 'decay_smart_scheduler_service.dart';
import 'booster_pack_factory.dart';
import '../screens/training_session_screen.dart';

/// Starts a review session for decayed tags.
class DailyReviewBoosterLauncher {
  DailyReviewBoosterLauncher();

  /// Builds today's booster pack and opens the training screen.
  Future<void> launch(BuildContext context) async {
    final plan = await DecaySmartSchedulerService().generateTodayPlan();
    final tags = plan.tags;
    if (tags.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Сегодня ничего не забыто!')));
      return;
    }

    final pack = await BoosterPackFactory.buildFromTags(tags);
    if (pack == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Сегодня ничего не забыто!')));
      return;
    }

    Navigator.pushNamed(context, TrainingSessionScreen.route, arguments: pack);
  }
}
