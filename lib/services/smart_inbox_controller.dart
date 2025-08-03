import 'package:flutter/widgets.dart';

import '../widgets/inbox_pinned_block_booster_banner.dart';
import 'smart_pinned_block_booster_provider.dart';

/// Aggregates smart inbox items for the user.
class SmartInboxController {
  SmartInboxController({SmartPinnedBlockBoosterProvider? boosterProvider})
    : boosterProvider = boosterProvider ?? SmartPinnedBlockBoosterProvider();

  final SmartPinnedBlockBoosterProvider boosterProvider;

  /// Returns widgets to display in the smart inbox.
  Future<List<Widget>> getInboxItems() async {
    final items = <Widget>[];
    final boosters = await boosterProvider.getBoosters();
    if (boosters.isNotEmpty) {
      items.add(
        InboxPinnedBlockBoosterBanner(suggestions: boosters.take(2).toList()),
      );
    }
    return items;
  }
}
