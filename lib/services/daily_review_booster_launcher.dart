import 'package:flutter/material.dart';

import 'decay_smart_scheduler_service.dart';
import 'booster_pack_factory.dart';
import '../screens/training_session_screen.dart';
import '../utils/snackbar_util.dart';

/// Starts a review session for decayed tags.
class DailyReviewBoosterLauncher {
  const DailyReviewBoosterLauncher();

  /// Builds today's booster pack and opens the training screen.
  Future<void> launch(BuildContext context) async {
    final plan = await DecaySmartSchedulerService().generateTodayPlan();
    final tags = plan.tags;
    if (tags.isEmpty) {
      SnackbarUtil.showMessage(context, 'Сегодня ничего не забыто!');
      return;
    }

    final pack = await BoosterPackFactory.buildFromTags(tags);
    if (pack == null) {
      SnackbarUtil.showMessage(context, 'Сегодня ничего не забыто!');
      return;
    }

    Navigator.pushNamed(
      context,
      TrainingSessionScreen.route,
      arguments: pack,
    );
  }
}
