import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ABTestEngine extends ChangeNotifier {
  static const _seedKey = 'ab_seed';
  static const _flagsKey = 'ab_flags';
  static ABTestEngine? _instance;
  static ABTestEngine get instance => _instance!;

  int _seed = 0;
  final Map<String, bool> _flags = {};

  bool get confettiEnabled => _flags['confetti_enabled'] ?? true;

  ABTestEngine() {
    _instance = this;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _seed = prefs.getInt(_seedKey) ?? Random().nextInt(1 << 31);
    final raw = prefs.getString(_flagsKey);
    if (raw != null) {
      final data = jsonDecode(raw);
      if (data is Map) {
        for (final e in data.entries) {
          _flags[e.key] = e.value == true;
        }
      }
    }
    if (!_flags.containsKey('confetti_enabled')) {
      final r = Random(_seed);
      _flags['confetti_enabled'] = r.nextBool();
      await _save();
    } else {
      await prefs.setInt(_seedKey, _seed);
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seedKey, _seed);
    await prefs.setString(_flagsKey, jsonEncode(_flags));
  }

  Map<String, dynamic> toMap() => {
        'seed': _seed,
        'flags': _flags,
      };

  Future<void> applyMap(Map<String, dynamic> data) async {
    bool changed = false;
    final seed = data['seed'];
    if (seed is int && _seed == 0) {
      _seed = seed;
      changed = true;
    }
    final flags = data['flags'];
    if (flags is Map) {
      for (final e in flags.entries) {
        final val = e.value == true;
        if (!_flags.containsKey(e.key)) {
          _flags[e.key] = val;
          changed = true;
        }
      }
    }
    if (changed) {
      await _save();
      notifyListeners();
    }
  }
}
