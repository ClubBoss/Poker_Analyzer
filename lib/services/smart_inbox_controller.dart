import 'package:flutter/widgets.dart';

import '../widgets/inbox_pinned_block_booster_banner.dart';
import 'smart_booster_diversity_scheduler_service.dart';
import 'smart_booster_inbox_limiter_service.dart';
import 'smart_pinned_block_booster_provider.dart';

/// Aggregates smart inbox items for the user.
class SmartInboxController {
  SmartInboxController({
    SmartPinnedBlockBoosterProvider? boosterProvider,
    SmartBoosterInboxLimiterService? inboxLimiter,
    SmartBoosterDiversitySchedulerService? diversityScheduler,
  })  : boosterProvider = boosterProvider ?? SmartPinnedBlockBoosterProvider(),
        inboxLimiter = inboxLimiter ?? SmartBoosterInboxLimiterService(),
        diversityScheduler =
            diversityScheduler ?? SmartBoosterDiversitySchedulerService();

  final SmartPinnedBlockBoosterProvider boosterProvider;
  final SmartBoosterInboxLimiterService inboxLimiter;
  final SmartBoosterDiversitySchedulerService diversityScheduler;

  /// Builds booster widgets to display in the smart inbox.
  Future<List<Widget>> buildBoosterInbox() async {
    final items = <Widget>[];
    final boosters = await boosterProvider.getBoosters();
    if (boosters.isNotEmpty) {
      final scheduled = await diversityScheduler.schedule(boosters);
      final allowed = <PinnedBlockBoosterSuggestion>[];
      for (final b in scheduled) {
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
