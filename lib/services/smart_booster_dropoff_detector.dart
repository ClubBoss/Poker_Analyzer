import 'package:shared_preferences/shared_preferences.dart';

/// Detects when a user frequently abandons booster drills.
class SmartBoosterDropoffDetector {
  SmartBoosterDropoffDetector._();
  static final SmartBoosterDropoffDetector instance =
      SmartBoosterDropoffDetector._();

  static const String _recentKey = 'booster_dropoff_recent';
  static const String _cooldownKey = 'booster_dropoff_cooldown';

  Future<List<String>> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentKey) ?? <String>[];
  }

  Future<void> _saveRecent(List<String> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentKey, list);
  }

  Future<DateTime?> _loadCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_cooldownKey);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  Future<void> _setCooldown(Duration duration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cooldownKey,
      DateTime.now().add(duration).toIso8601String(),
    );
  }

  /// Records outcome of a booster drill.
  /// Possible values: 'completed', 'failed', 'skipped', 'closed'.
  Future<void> recordOutcome(String outcome) async {
    final list = await _loadRecent();
    list.add(outcome);
    while (list.length > 5) {
      list.removeAt(0);
    }
    await _saveRecent(list);
  }

  /// Returns true if user is in a dropoff state and recaps should be suppressed.
  Future<bool> isInDropoffState([
    Duration cooldown = const Duration(hours: 6),
  ]) async {
    final until = await _loadCooldown();
    if (until != null) {
      if (DateTime.now().isBefore(until)) return true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cooldownKey);
    }
    final list = await _loadRecent();
    final dropCount = list
        .where((e) => e == 'failed' || e == 'skipped' || e == 'closed')
        .length;
    if (list.length >= 5 && dropCount >= 3) {
      await _setCooldown(cooldown);
      return true;
    }
    return false;
  }
}
