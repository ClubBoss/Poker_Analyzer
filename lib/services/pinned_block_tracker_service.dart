import 'package:shared_preferences/shared_preferences.dart';

/// Tracks pin/unpin actions for theory blocks and exposes basic analytics.
class PinnedBlockTrackerService {
  PinnedBlockTrackerService._();

  /// Singleton instance.
  static final PinnedBlockTrackerService instance =
      PinnedBlockTrackerService._();

  static String _pinKey(String id) => 'pinned_block_$id';
  static String _lastPinKey(String id) => 'pinned_block_last_$id';

  /// Records that the block with [blockId] was pinned.
  Future<void> logPin(String blockId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinKey(blockId), true);
    await prefs.setInt(
      _lastPinKey(blockId),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Records that the block with [blockId] was unpinned.
  Future<void> logUnpin(String blockId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey(blockId));
  }

  /// Returns the last time the block with [blockId] was pinned.
  Future<DateTime?> getLastPinTime(String blockId) async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_lastPinKey(blockId));
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  /// Whether the block with [blockId] is currently pinned.
  Future<bool> isPinned(String blockId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pinKey(blockId)) ?? false;
  }

  /// Returns all currently pinned block ids.
  Future<List<String>> getPinnedBlockIds() async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'pinned_block_';
    final lastPrefix = 'pinned_block_last_';
    final ids = <String>[];
    for (final key in prefs.getKeys()) {
      if (key.startsWith(prefix) && !key.startsWith(lastPrefix)) {
        if (prefs.getBool(key) ?? false) {
          ids.add(key.substring(prefix.length));
        }
      }
    }
    return ids;
  }
}
