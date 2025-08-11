import 'package:shared_preferences/shared_preferences.dart';


/// Provides a cached [SharedPreferences] instance and exports preference keys.
class PreferencesService {
  PreferencesService._();

  static SharedPreferences? _prefs;

  /// Returns the cached [SharedPreferences] instance, initializing it if necessary.
  static Future<SharedPreferences> getInstance() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Accessor for the cached [SharedPreferences] instance.
  ///
  /// Ensure [getInstance] is called at least once before using this getter.
  static SharedPreferences get instance => _prefs!;
}

// Re-export keys so consumers only need to import this service.
export '../utils/shared_prefs_keys.dart';
