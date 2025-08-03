import 'package:flutter/widgets.dart';

import '../widgets/inbox_pinned_block_booster_banner.dart';
import 'smart_booster_inbox_limiter_service.dart';
import 'smart_pinned_block_booster_provider.dart';

/// Aggregates smart inbox items for the user.
class SmartInboxController {
  SmartInboxController({
    SmartPinnedBlockBoosterProvider? boosterProvider,
    SmartBoosterInboxLimiterService? inboxLimiter,
  })  : boosterProvider = boosterProvider ?? SmartPinnedBlockBoosterProvider(),
        inboxLimiter = inboxLimiter ?? SmartBoosterInboxLimiterService();

  final SmartPinnedBlockBoosterProvider boosterProvider;
  final SmartBoosterInboxLimiterService inboxLimiter;

  /// Returns widgets to display in the smart inbox.
  Future<List<Widget>> getInboxItems() async {
    final items = <Widget>[];
    final boosters = await boosterProvider.getBoosters();
    if (boosters.isNotEmpty) {
      final allowed = <PinnedBlockBoosterSuggestion>[];
      for (final b in boosters) {
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
