import 'package:flutter/widgets.dart';

import '../widgets/inbox_pinned_block_booster_banner.dart';
import 'smart_booster_diversity_scheduler_service.dart';
import 'smart_booster_inbox_limiter_service.dart';
import 'smart_pinned_block_booster_provider.dart';
import 'smart_inbox_item_deduplication_service.dart';

/// Aggregates smart inbox items for the user.
class SmartInboxController {
  SmartInboxController({
    SmartPinnedBlockBoosterProvider? boosterProvider,
    SmartBoosterInboxLimiterService? inboxLimiter,
    SmartBoosterDiversitySchedulerService? diversityScheduler,
    SmartInboxItemDeduplicationService? deduplicator,
  })  : boosterProvider = boosterProvider ?? SmartPinnedBlockBoosterProvider(),
        inboxLimiter = inboxLimiter ?? SmartBoosterInboxLimiterService(),
        diversityScheduler =
            diversityScheduler ?? SmartBoosterDiversitySchedulerService(),
        deduplicator =
            deduplicator ?? SmartInboxItemDeduplicationService();

  final SmartPinnedBlockBoosterProvider boosterProvider;
  final SmartBoosterInboxLimiterService inboxLimiter;
  final SmartBoosterDiversitySchedulerService diversityScheduler;
  final SmartInboxItemDeduplicationService deduplicator;

  /// Returns widgets to display in the smart inbox.
  Future<List<Widget>> getInboxItems() async {
    final items = <Widget>[];
    final boosters = await boosterProvider.getBoosters();
    if (boosters.isNotEmpty) {
      final scheduled = await diversityScheduler.schedule(boosters);
      final deduped = await deduplicator.deduplicate(scheduled);
      final allowed = <PinnedBlockBoosterSuggestion>[];
      for (final b in deduped) {
        if (await inboxLimiter.canShow(b.tag)) {
          await inboxLimiter.recordShown(b.tag);
          allowed.add(b);
        }
        if (allowed.length >= SmartBoosterInboxLimiterService.maxPerDay) break;
      }
      if (allowed.isNotEmpty) {
        items.add(InboxPinnedBlockBoosterBanner(suggestions: allowed));
      }
    }
    return items;
  }
}
