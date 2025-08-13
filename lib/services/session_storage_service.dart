import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight key-value store with expiration timestamps.
class SessionStorageService {
  SessionStorageService._();

  static final SessionStorageService instance = SessionStorageService._();

  static const _timeSuffix = '_time';

  /// Returns the stored integer value for [key] if any.
  Future<int?> getInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

  /// Returns the last updated timestamp for [key] if any.
  Future<DateTime?> getTimestamp(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('$key$_timeSuffix');
    return str == null ? null : DateTime.tryParse(str);
  }

  /// Stores [value] for [key] and updates its timestamp.
  Future<void> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
    await prefs.setString('$key$_timeSuffix', DateTime.now().toIso8601String());
  }

  /// Removes value and timestamp associated with [key].
  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    await prefs.remove('$key$_timeSuffix');
  }
}
