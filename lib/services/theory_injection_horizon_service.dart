import 'package:shared_preferences/shared_preferences.dart';

/// Enforces minimum delay between theory booster injections.
class TheoryInjectionHorizonService {
  TheoryInjectionHorizonService._();
  static final TheoryInjectionHorizonService instance =
      TheoryInjectionHorizonService._();

  static const String _prefsPrefix = 'theory_inject_last_';

  final Map<String, DateTime?> _cache = {};

  Future<DateTime?> _getLast(String type) async {
    if (_cache.containsKey(type)) return _cache[type];
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('$_prefsPrefix$type');
    final ts = str == null ? null : DateTime.tryParse(str);
    _cache[type] = ts;
    return ts;
  }

  /// Returns `true` if enough time has passed since last [type] injection.
  Future<bool> canInject(
    String type, {
    Duration minGap = const Duration(hours: 6),
  }) async {
    final last = await _getLast(type);
    if (last == null) return true;
    return DateTime.now().difference(last) >= minGap;
  }

  /// Updates last injection timestamp for [type] to now.
  Future<void> markInjected(String type) async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefsPrefix$type', now.toIso8601String());
    _cache[type] = now;
  }
}
