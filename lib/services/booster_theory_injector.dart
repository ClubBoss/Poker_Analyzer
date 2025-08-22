import 'package:flutter/material.dart';

import '../models/mistake_tag.dart';
import '../models/v2/training_pack_spot.dart';
import '../widgets/theory_recap_dialog.dart';
import 'suggestion_cooldown_manager.dart';

enum BoosterTheoryInjectionMode { preDrill, postDrill }

/// Injects theory recap dialogs into booster drills based on weakness tags.
class BoosterTheoryInjector {
  final BoosterTheoryInjectionMode mode;
  BoosterTheoryInjector({this.mode = BoosterTheoryInjectionMode.preDrill});

  /// Shows a [TheoryRecapDialog] when [spot] contains a tag in [weakTags].
  Future<void> maybeInject(
    BuildContext context, {
    required TrainingPackSpot spot,
    required List<MistakeTag> weakTags,
  }) async {
    final spotTags = {for (final t in spot.tags) t.trim().toLowerCase()};
    MistakeTag? matched;
    for (final tag in weakTags) {
      if (spotTags.contains(tag.name.toLowerCase())) {
        matched = tag;
        break;
      }
    }
    if (matched == null) return;
    final key = 'booster_theory_${matched.name.toLowerCase()}';
    final underCooldown = await SuggestionCooldownManager.isUnderCooldown(
      key,
      cooldown: const Duration(days: 1),
    );
    if (underCooldown) return;
    await showTheoryRecapDialog(
      context,
      tags: [matched.name],
      trigger: 'booster',
    );
    await SuggestionCooldownManager.markSuggested(key);
  }
}
