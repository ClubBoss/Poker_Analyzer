import 'package:flutter/widgets.dart';

import '../widgets/inbox_pinned_block_booster_banner.dart';
import '../widgets/smart_inbox_debug_banner_widget.dart';
import 'smart_inbox_debug_service.dart';
import 'smart_booster_diversity_scheduler_service.dart';
import 'smart_booster_inbox_limiter_service.dart';
import 'smart_pinned_block_booster_provider.dart';
import 'smart_inbox_item_deduplication_service.dart';
import 'smart_inbox_priority_scorer_service.dart';

/// Aggregates smart inbox items for the user.
class SmartInboxController {
  SmartInboxController({
    SmartPinnedBlockBoosterProvider? boosterProvider,
    SmartBoosterInboxLimiterService? inboxLimiter,
    SmartBoosterDiversitySchedulerService? diversityScheduler,
    SmartInboxItemDeduplicationService? deduplicator,
    SmartInboxPriorityScorerService? priorityScorer,
  })  : boosterProvider = boosterProvider ?? SmartPinnedBlockBoosterProvider(),
        inboxLimiter = inboxLimiter ?? SmartBoosterInboxLimiterService(),
        diversityScheduler =
            diversityScheduler ?? SmartBoosterDiversitySchedulerService(),
        deduplicator =
            deduplicator ?? SmartInboxItemDeduplicationService(),
        priorityScorer =
            priorityScorer ?? SmartInboxPriorityScorerService();

  final SmartPinnedBlockBoosterProvider boosterProvider;
  final SmartBoosterInboxLimiterService inboxLimiter;
  final SmartBoosterDiversitySchedulerService diversityScheduler;
  final SmartInboxItemDeduplicationService deduplicator;
  final SmartInboxPriorityScorerService priorityScorer;

  /// Builds booster widgets to display in the smart inbox.
  Future<List<Widget>> buildBoosterInbox() async {
    final items = <Widget>[];
    final boosters = await boosterProvider.getBoosters();
    var scheduled = <PinnedBlockBoosterSuggestion>[];
    var deduped = <PinnedBlockBoosterSuggestion>[];
    var sorted = <PinnedBlockBoosterSuggestion>[];
    var allowed = <PinnedBlockBoosterSuggestion>[];

    if (boosters.isNotEmpty) {
      scheduled = await diversityScheduler.schedule(boosters);
      deduped = await deduplicator.deduplicate(scheduled);
      sorted = await priorityScorer.sort(deduped);
      allowed = await _buildAllowedInboxBoosters(sorted);
      if (allowed.isNotEmpty) {
        items.add(InboxPinnedBlockBoosterBanner(suggestions: allowed));
      }
    }

    final debugSvc = SmartInboxDebugService.instance;
    debugSvc.update(SmartInboxDebugInfo(
      raw: boosters,
      scheduled: scheduled,
      deduplicated: deduped,
      sorted: sorted,
      limited: allowed,
      rendered: allowed,
    ));
    if (debugSvc.enabled) {
      items.insert(0, const SmartInboxDebugBannerWidget());
    }
    return items;
  }

  Future<List<PinnedBlockBoosterSuggestion>> _buildAllowedInboxBoosters(
      List<PinnedBlockBoosterSuggestion> suggestions) async {
    final allowed = <PinnedBlockBoosterSuggestion>[];
    for (final b in suggestions) {
      if (await inboxLimiter.canShow(b.tag)) {
        await inboxLimiter.recordShown(b.tag);
        allowed.add(b);
      }
      if (allowed.length >= SmartBoosterInboxLimiterService.maxPerDay) break;
    }
    return allowed;
  }
}
