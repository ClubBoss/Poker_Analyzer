import 'package:shared_preferences/shared_preferences.dart';

/// Stores per-tag mistake telemetry in [SharedPreferences].
class MistakeTelemetryStore {
  static const _errPrefix = 'telemetry.errors.';
  static const _seenPrefix = 'telemetry.lastSeen.';

  /// Returns error rates per tag in the range 0..1.
  Future<Map<String, double>> getErrorRates() async {
    final prefs = await SharedPreferences.getInstance();
    final res = <String, double>{};
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_errPrefix)) {
        final tag = key.substring(_errPrefix.length);
        final v = prefs.getDouble(key) ?? 0;
        res[tag] = v.clamp(0.0, 1.0);
      }
    }
    return res;
  }

  /// Records a mistake for [tag] with optional [weight].
  Future<void> recordMistake(String tag, {double weight = 1.0}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_errPrefix$tag';
    final current = prefs.getDouble(key) ?? 0.0;
    await prefs.setDouble(key, (current + weight).clamp(0.0, 1.0));
    await prefs.setString('$_seenPrefix$tag', DateTime.now().toIso8601String());
  }

  /// Returns last time a mistake for [tag] was recorded.
  Future<DateTime?> lastSeen(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_seenPrefix$tag');
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }
}
