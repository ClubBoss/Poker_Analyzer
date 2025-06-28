import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class CloudSyncService {
  CloudSyncService();

  final ValueNotifier<double> progress = ValueNotifier(0);
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  SharedPreferences? _prefs;
  Timer? _timer;
  final List<Map<String, dynamic>> _pending = [];
  late final String uid;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    uid = _prefs!.getString('cloud_user') ?? const Uuid().v4();
    await _prefs!.setString('cloud_user', uid);
    final list = _prefs!.getStringList('pending_mutations') ?? [];
    _pending
      ..clear()
      ..addAll(list.map((e) => jsonDecode(e) as Map<String, dynamic>));
  }

  Future<void> syncDown() async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return;
    for (final entry in data.entries) {
      await _prefs?.setString(entry.key, jsonEncode(entry.value));
    }
  }

  Future<void> syncUp() async {
    if (_prefs == null) return;
    final Map<String, dynamic> local = {};
    for (final key in _prefs!.getKeys()) {
      if (key == 'pending_mutations') continue;
      final value = _prefs!.getString(key);
      if (value != null) {
        local[key] = jsonDecode(value);
      }
    }
    final doc = _db.collection('users').doc(uid);
    progress.value = 0.0;
    await doc.set(local, SetOptions(merge: true));
    progress.value = 1.0;
    for (final m in _pending) {
      await doc.collection(m['col']).doc(m['id']).set(m['data'], SetOptions(merge: true));
    }
    _pending.clear();
    await _prefs!.setStringList('pending_mutations', []);
  }

  StreamSubscription watchChanges() {
    return _db.collection('users').doc(uid).snapshots().listen((event) {
      final data = event.data();
      if (data == null) return;
      for (final entry in data.entries) {
        _prefs?.setString(entry.key, jsonEncode(entry.value));
      }
    });
  }

  Future<void> queueMutation(String col, String id, Map<String, dynamic> data) async {
    _pending.add({'col': col, 'id': id, 'data': data});
    await _prefs?.setStringList('pending_mutations', _pending.map(jsonEncode).toList());
    _timer ??= Timer(const Duration(seconds: 5), () {
      _timer = null;
    });
  }

  Future<List<Map<String, dynamic>>> loadTrainingSessions() async {
    final jsonStr = _prefs?.getString('training_sessions');
    if (jsonStr == null) return [];
    final data = jsonDecode(jsonStr);
    if (data is List) {
      return [for (final e in data.whereType<Map>()) Map<String, dynamic>.from(e as Map)];
    }
    return [];
  }
}
