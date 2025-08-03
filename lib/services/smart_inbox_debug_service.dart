import 'package:flutter/foundation.dart';

import 'smart_pinned_block_booster_provider.dart';

class SmartInboxDebugService {
  SmartInboxDebugService._();

  static final SmartInboxDebugService instance = SmartInboxDebugService._();

  final ValueNotifier<bool> enabled = ValueNotifier(false);

  void toggle() => enabled.value = !enabled.value;
}

class SmartInboxDebugInfo {
  SmartInboxDebugInfo({
    required this.raw,
    required this.scheduled,
    required this.deduplicated,
    required this.sorted,
    required this.limited,
    required this.rendered,
  });

  final List<PinnedBlockBoosterSuggestion> raw;
  final List<PinnedBlockBoosterSuggestion> scheduled;
  final List<PinnedBlockBoosterSuggestion> deduplicated;
  final List<PinnedBlockBoosterSuggestion> sorted;
  final List<PinnedBlockBoosterSuggestion> limited;
  final List<PinnedBlockBoosterSuggestion> rendered;
}
