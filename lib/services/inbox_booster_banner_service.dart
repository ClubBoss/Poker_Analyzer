import 'package:flutter/foundation.dart';

/// Handles displaying inbox booster banners within the UI.
class InboxBoosterBannerService {
  InboxBoosterBannerService();

  /// Singleton instance.
  static final InboxBoosterBannerService instance = InboxBoosterBannerService();

  String? _lastTag;

  /// Shows an inbox banner for [tag].
  Future<void> show(String tag) async {
    _lastTag = tag;
  }

  /// Tag used in the last [show] call, for testing.
  @visibleForTesting
  String? get lastTag => _lastTag;

  /// Clears state for tests.
  @visibleForTesting
  void resetForTest() {
    _lastTag = null;
  }
}
