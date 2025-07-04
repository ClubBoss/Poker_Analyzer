import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'remote_config_service.dart';

class AbTestEngine extends ChangeNotifier {
  final RemoteConfigService remote;
  AbTestEngine({required this.remote});

  late final SharedPreferences _prefs;
  final Map<String, String> _cache = {};
  final Random _rand = Random();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final overrides = remote.get<Map<String, dynamic>>('experiments', {});
    for (final entry in overrides.entries) {
      final v = entry.value.toString();
      _cache[entry.key] = v;
      await _prefs.setString('abtest_${entry.key}', v);
    }
  }

  String variantFor(String id) {
    final cached = _cache[id];
    if (cached != null) return cached;
    var v = _prefs.getString('abtest_$id');
    if (v == null) {
      v = _rand.nextBool() ? 'A' : 'B';
      _prefs.setString('abtest_$id', v);
    }
    _cache[id] = v;
    return v;
  }

  bool isVariant(String id, String v) => variantFor(id) == v;
}
