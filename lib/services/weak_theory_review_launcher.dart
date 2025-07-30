import 'package:flutter/material.dart';

import '../models/mistake_tag.dart';
import '../models/mistake_tag_history_entry.dart';
import '../widgets/theory_recap_dialog.dart';
import 'mistake_tag_history_service.dart';
import 'theory_replay_cooldown_manager.dart';

/// Launches theory recap when repeated weaknesses are detected.
class WeakTheoryReviewLauncher {
  /// Minimum mistakes on the same tag required to trigger recap.
  final int threshold;

  /// Number of recent packs to analyze for repeated mistakes.
  final int sessionLimit;

  const WeakTheoryReviewLauncher({
    this.threshold = 3,
    this.sessionLimit = 5,
  });

  /// Checks recent mistakes and opens a [TheoryRecapDialog] if thresholds are exceeded.
  Future<void> maybeLaunch(BuildContext context) async {
    final history =
        await MistakeTagHistoryService.getRecentHistory(limit: 100);
    if (history.isEmpty) return;

    final packs = <String>[];
    final relevant = <MistakeTagHistoryEntry>[];
    for (final entry in history) {
      if (!packs.contains(entry.packId)) {
        packs.add(entry.packId);
        if (packs.length > sessionLimit) break;
      }
      if (packs.contains(entry.packId)) {
        relevant.add(entry);
      }
    }

    final tagCounts = <MistakeTag, int>{};
    final tagPacks = <MistakeTag, Set<String>>{};

    for (final entry in relevant) {
      for (final tag in entry.tags) {
        tagCounts.update(tag, (v) => v + 1, ifAbsent: () => 1);
        tagPacks.putIfAbsent(tag, () => <String>{}).add(entry.packId);
      }
    }

    if (tagCounts.isEmpty) return;

    final sorted = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final e in sorted) {
      final tag = e.key;
      final count = e.value;
      final packCount = tagPacks[tag]?.length ?? 0;
      if (count < threshold || packCount < 2) continue;
      final key = 'weak_theory_${tag.name.toLowerCase()}';
      if (await TheoryReplayCooldownManager.isUnderCooldown(
        key,
        cooldown: const Duration(days: 1),
      )) {
        continue;
      }
      await showTheoryRecapDialog(
        context,
        tags: [tag.name],
        trigger: 'weakness',
      );
      await TheoryReplayCooldownManager.markSuggested(key);
      break;
    }
  }
}
