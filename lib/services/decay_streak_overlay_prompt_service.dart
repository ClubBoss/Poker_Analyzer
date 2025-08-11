import 'package:flutter/material.dart';

import '../widgets/decay_streak_overlay_banner.dart';
import 'decay_streak_tracker_service.dart';
import 'booster_inbox_delivery_service.dart';
import 'decay_tag_retention_tracker_service.dart';
import 'decay_spot_booster_engine.dart';
import 'decay_booster_training_launcher.dart';

/// Shows a reminder overlay when the decay streak is at risk of breaking.
class DecayStreakOverlayPromptService {
  final DecayStreakTrackerService streaks;
  final BoosterInboxDeliveryService inbox;
  final DecayTagRetentionTrackerService retention;
  final DecaySpotBoosterEngine boosterEngine;
  final DecayBoosterTrainingLauncher launcher;

  DecayStreakOverlayPromptService({
    DecayStreakTrackerService? streaks,
    BoosterInboxDeliveryService? inbox,
    DecayTagRetentionTrackerService? retention,
    DecaySpotBoosterEngine? boosterEngine,
    DecayBoosterTrainingLauncher? launcher,
  })  : streaks = streaks ?? const DecayStreakTrackerService(),
        inbox = inbox ?? BoosterInboxDeliveryService.instance,
        retention = retention ?? const DecayTagRetentionTrackerService(),
        boosterEngine = boosterEngine ?? DecaySpotBoosterEngine(),
        launcher = launcher ?? const DecayBoosterTrainingLauncher();

  OverlayEntry? _entry;

  /// Shows an overlay if user is about to lose the decay streak.
  Future<void> maybeShowOverlayIfStreakAtRisk(BuildContext context) async {
    if (_entry != null) return;
    final now = DateTime.now();
    if (now.hour < 20) return;

    final streak = await streaks.getCurrentStreak();
    if (streak < 1) return;

    final tag = await inbox.getNextDeliverableTag();
    if (tag == null) return;
    final last = await retention.getLastBoosterCompletion(tag);
    if (last != null &&
        last.year == now.year &&
        last.month == now.month &&
        last.day == now.day) {
      return;
    }

    final overlay = Overlay.of(context);

    void remove() {
      _entry?.remove();
      _entry = null;
    }

    Future<void> open() async {
      remove();
      await boosterEngine.enqueueForTag(tag);
      await launcher.launch();
    }

    _entry = OverlayEntry(
      builder: (_) => DecayStreakOverlayBanner(
        tag: tag,
        onDismiss: remove,
        onOpen: open,
      ),
    );
    overlay.insert(_entry!);
  }
}
