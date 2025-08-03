import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  SharedPreferencesService._();
  static final SharedPreferencesService instance = SharedPreferencesService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _sp => _prefs!;
  SharedPreferences get prefs => _sp;

  String? getString(String key) => _sp.getString(key);
  Future<bool> setString(String key, String value) => _sp.setString(key, value);

  bool? getBool(String key) => _sp.getBool(key);
  Future<bool> setBool(String key, bool value) => _sp.setBool(key, value);

  int? getInt(String key) => _sp.getInt(key);
  Future<bool> setInt(String key, int value) => _sp.setInt(key, value);

  double? getDouble(String key) => _sp.getDouble(key);
  Future<bool> setDouble(String key, double value) => _sp.setDouble(key, value);

  List<String>? getStringList(String key) => _sp.getStringList(key);
  Future<bool> setStringList(String key, List<String> value) =>
      _sp.setStringList(key, value);

  bool containsKey(String key) => _sp.containsKey(key);
  Future<bool> remove(String key) => _sp.remove(key);
}
