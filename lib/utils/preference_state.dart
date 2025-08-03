import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin PreferenceState<T extends StatefulWidget> on State<T> {
  static SharedPreferences? _cachedPrefs;
  late final SharedPreferences prefs;
  bool _prefsReady = false;
  bool get prefsReady => _prefsReady;

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    prefs = _cachedPrefs ??= await SharedPreferences.getInstance();
    _prefsReady = true;
    if (mounted) onPrefsLoaded();
  }

  void onPrefsLoaded() {}
}

