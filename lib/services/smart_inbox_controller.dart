import 'package:flutter/widgets.dart';

import '../widgets/inbox_pinned_block_booster_banner.dart';
import '../widgets/smart_inbox_debug_banner_widget.dart';
import 'smart_booster_diversity_scheduler_service.dart';
import 'smart_booster_inbox_limiter_service.dart';
import 'smart_inbox_debug_service.dart';
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

  /// Returns widgets to display in the smart inbox.
  Future<List<Widget>> getInboxItems() async {
    final items = <Widget>[];
    final raw = await boosterProvider.getBoosters();
    if (raw.isNotEmpty) {
      final scheduled = await diversityScheduler.schedule(raw);
      final deduped = await deduplicator.deduplicate(scheduled);
      final sorted = await priorityScorer.sort(deduped);
      final limited = <PinnedBlockBoosterSuggestion>[];
      for (final b in sorted) {
        if (await inboxLimiter.canShow(b.tag)) {
          await inboxLimiter.recordShown(b.tag);
          limited.add(b);
        }
        if (limited.length >= SmartBoosterInboxLimiterService.maxPerDay) break;
      }
      if (limited.isNotEmpty) {
        items.add(InboxPinnedBlockBoosterBanner(suggestions: limited));
      }
      if (SmartInboxDebugService.instance.enabled.value) {
        items.add(
          SmartInboxDebugBannerWidget(
            info: SmartInboxDebugInfo(
              raw: raw,
              scheduled: scheduled,
              deduplicated: deduped,
              sorted: sorted,
              limited: limited,
              rendered: limited,
            ),
          ),
        );
      }
    }
    return items;
  }
}
