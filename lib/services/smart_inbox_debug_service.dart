import 'package:flutter/foundation.dart';

import 'smart_pinned_block_booster_provider.dart';

/// Holds debug information for the Smart Inbox pipeline stages.
class SmartInboxDebugInfo {
  final List<PinnedBlockBoosterSuggestion> raw;
  final List<PinnedBlockBoosterSuggestion> scheduled;
  final List<PinnedBlockBoosterSuggestion> deduplicated;
  final List<PinnedBlockBoosterSuggestion> sorted;
  final List<PinnedBlockBoosterSuggestion> limited;
  final List<PinnedBlockBoosterSuggestion> rendered;

  const SmartInboxDebugInfo({
    required this.raw,
    required this.scheduled,
    required this.deduplicated,
    required this.sorted,
    required this.limited,
    required this.rendered,
  });
}

/// Global service storing Smart Inbox debug state.
class SmartInboxDebugService extends ChangeNotifier {
  SmartInboxDebugService._();

  /// Singleton instance.
  static final SmartInboxDebugService instance = SmartInboxDebugService._();

  /// Latest debug info from the controller.
  SmartInboxDebugInfo? info;

  /// Whether the debug banner should be shown.
  bool enabled = false;

  /// Updates [info] and notifies listeners.
  void update(SmartInboxDebugInfo data) {
    info = data;
    notifyListeners();
  }

  /// Toggles the debug banner visibility.
  void toggle() {
    enabled = !enabled;
    notifyListeners();
  }
}
