import 'package:shared_preferences/shared_preferences.dart';

import '../utils/shared_prefs_keys.dart';

/// Provides a cached [SharedPreferences] instance along with convenient
/// asynchronous getters and setters for common preference types. The service
/// also re-exports preference keys so consumers only need to import this file.
class PreferencesService {
  PreferencesService._();

  static SharedPreferences? _prefs;

  /// Returns the cached [SharedPreferences] instance, initializing it if
  /// necessary.
  static Future<SharedPreferences> getInstance() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Accessor for the cached [SharedPreferences] instance.
  /// Ensure [getInstance] is called at least once before using this getter.
  static SharedPreferences get instance => _prefs!;

  /// Retrieves a `bool` value for the given [key].
  static Future<bool?> getBool(String key) async {
    final prefs = await getInstance();
    return prefs.getBool(key);
  }

  /// Persists a `bool` [value] for the given [key].
  static Future<void> setBool(String key, bool value) async {
    final prefs = await getInstance();
    await prefs.setBool(key, value);
  }

  /// Retrieves an `int` value for the given [key].
  static Future<int?> getInt(String key) async {
    final prefs = await getInstance();
    return prefs.getInt(key);
  }

  /// Persists an `int` [value] for the given [key].
  static Future<void> setInt(String key, int value) async {
    final prefs = await getInstance();
    await prefs.setInt(key, value);
  }

  /// Retrieves a `double` value for the given [key].
  static Future<double?> getDouble(String key) async {
    final prefs = await getInstance();
    return prefs.getDouble(key);
  }

  /// Persists a `double` [value] for the given [key].
  static Future<void> setDouble(String key, double value) async {
    final prefs = await getInstance();
    await prefs.setDouble(key, value);
  }

  /// Retrieves a `String` value for the given [key].
  static Future<String?> getString(String key) async {
    final prefs = await getInstance();
    return prefs.getString(key);
  }

  /// Persists a `String` [value] for the given [key].
  static Future<void> setString(String key, String value) async {
    final prefs = await getInstance();
    await prefs.setString(key, value);
  }

  /// Retrieves a list of strings for the given [key].
  static Future<List<String>?> getStringList(String key) async {
    final prefs = await getInstance();
    return prefs.getStringList(key);
  }

  /// Persists a list of strings [value] for the given [key].
  static Future<void> setStringList(String key, List<String> value) async {
    final prefs = await getInstance();
    await prefs.setStringList(key, value);
  }

  /// Removes the value associated with the given [key].
  static Future<void> remove(String key) async {
    final prefs = await getInstance();
    await prefs.remove(key);
  }
}

// Re-export keys so consumers only need to import this service.
export '../utils/shared_prefs_keys.dart';
