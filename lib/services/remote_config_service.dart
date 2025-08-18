import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cloud_retry_policy.dart';

class RemoteConfigService extends ChangeNotifier {
  final ValueNotifier<Map<String, dynamic>> data = ValueNotifier({});
  Map<String, dynamic> _data = {};
  DateTime? _lastFetch;

  T get<T>(String key, T def) {
    final v = _data[key];
    if (v is T) return v;
    return def;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('remote_config_json');
    final ts = prefs.getInt('remote_config_ts');
    if (json != null) {
      _data = jsonDecode(json) as Map<String, dynamic>;
    }
    if (ts != null) _lastFetch = DateTime.fromMillisecondsSinceEpoch(ts);
    data.value = Map.from(_data);
    final now = DateTime.now();
    if (_lastFetch == null || now.difference(_lastFetch!).inHours >= 12) {
      try {
        final doc = await CloudRetryPolicy.execute(
          () => FirebaseFirestore.instance
              .collection('config')
              .doc('public')
              .get(),
        );
        if (doc.exists) {
          _data = doc.data() ?? {};
          data.value = Map.from(_data);
          await prefs.setString('remote_config_json', jsonEncode(_data));
          await prefs.setInt('remote_config_ts', now.millisecondsSinceEpoch);
          _lastFetch = now;
          notifyListeners();
        }
      } catch (_) {}
    }
  }

  Future<void> reload() async {
    try {
      final doc = await CloudRetryPolicy.execute(
        () =>
            FirebaseFirestore.instance.collection('config').doc('public').get(),
      );
      if (doc.exists) {
        final prefs = await SharedPreferences.getInstance();
        final now = DateTime.now();
        _data = doc.data() ?? {};
        data.value = Map.from(_data);
        await prefs.setString('remote_config_json', jsonEncode(_data));
        await prefs.setInt('remote_config_ts', now.millisecondsSinceEpoch);
        _lastFetch = now;
        notifyListeners();
      }
    } catch (_) {}
  }
}
