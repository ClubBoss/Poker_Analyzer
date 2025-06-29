import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CloudSyncService {
  CloudSyncService();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late SharedPreferences _prefs;
  Box? _box;
  static bool get isLocal => kIsWeb ||
      (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS));
  bool get _local => CloudSyncService.isLocal;
  String? get uid => FirebaseAuth.instance.currentUser?.uid;
  final List<Map<String, dynamic>> _pending = [];
  final ValueNotifier<DateTime?> lastSync = ValueNotifier(null);

  Future<void> init() async {
    if (_local) {
      await Hive.initFlutter();
      _box = await Hive.openBox('cloud_cache');
      final list = (_box!.get('pending_mutations') as List?) ?? [];
      _pending
        ..clear()
        ..addAll(list.cast<Map>().map((e) => Map<String, dynamic>.from(e)));
      final ts = _box!.get('last_sync') as String?;
      if (ts != null) lastSync.value = DateTime.tryParse(ts);
    } else {
      _prefs = await SharedPreferences.getInstance();
      _db.settings = const Settings(persistenceEnabled: true);
      final list = _prefs.getStringList('pending_mutations') ?? [];
      _pending
        ..clear()
        ..addAll(list.map((e) => jsonDecode(e) as Map<String, dynamic>));
      final ts = _prefs.getString('last_sync');
      if (ts != null) lastSync.value = DateTime.tryParse(ts);
    }
  }

  Future<void> syncUp() async {
    if (_pending.isEmpty || uid == null) return;
    if (_local) {
      for (final m in _pending) {
        _box!.put('${m['col']}_${m['id']}', m['data']);
        _box!.put('cached_${m['col']}', m['data']);
      }
      _pending.clear();
      await _box!.put('pending_mutations', _pending);
      lastSync.value = DateTime.now();
      await _box!.put('last_sync', lastSync.value!.toIso8601String());
      return;
    }
    final user = _db.collection('users').doc(uid);
    final batch = _db.batch();
    for (final m in _pending) {
      final ref = user.collection(m['col'] as String).doc(m['id'] as String);
      batch.set(ref, m['data'] as Map<String, dynamic>, SetOptions(merge: true));
    }
    try {
      await batch.commit();
      _pending.clear();
      await _prefs.setStringList('pending_mutations', []);
      lastSync.value = DateTime.now();
      await _prefs.setString('last_sync', lastSync.value!.toIso8601String());
    } catch (_) {}
  }

  Future<void> syncDown() async {
    if (uid == null) return;
    if (_local) {
      final ts = _box!.get('last_sync') as String?;
      if (ts != null) lastSync.value = DateTime.tryParse(ts);
      return;
    }
    final user = _db.collection('users').doc(uid);
    for (final col in ['training_spots', 'training_stats', 'preferences']) {
      final snap = await user.collection(col).doc('main').get();
      if (!snap.exists) continue;
      final remote = snap.data()!;
      final localStr = _prefs.getString('cached_$col');
      final local = localStr != null ? jsonDecode(localStr) as Map<String, dynamic> : null;
      final remoteAt = DateTime.tryParse(remote['updatedAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final localAt = DateTime.tryParse(local?['updatedAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (remoteAt.isAfter(localAt)) {
        await _prefs.setString('cached_$col', jsonEncode(remote));
      }
    }
    final ts = _prefs.getString('last_sync');
    if (ts != null) lastSync.value = DateTime.tryParse(ts);
  }

  Future<void> queueMutation(String col, String id, Map<String, dynamic> data) async {
    _pending.removeWhere((e) => e['col'] == col && e['id'] == id);
    _pending.add({'col': col, 'id': id, 'data': data});
    if (_local) {
      await _box!.put('pending_mutations', _pending);
      await _box!.put('cached_$col', data);
    } else {
      await _prefs.setStringList('pending_mutations', _pending.map(jsonEncode).toList());
      await _prefs.setString('cached_$col', jsonEncode(data));
    }
  }

  Map<String, dynamic>? getCached(String col) {
    if (_local) {
      final val = _box!.get('cached_$col');
      if (val is Map) return Map<String, dynamic>.from(val as Map);
      if (val is String) return jsonDecode(val) as Map<String, dynamic>;
      return null;
    }
    final str = _prefs.getString('cached_$col');
    return str != null ? jsonDecode(str) as Map<String, dynamic> : null;
  }

  void watchChanges() {
    if (_local || uid == null) return;
    for (final col in ['training_spots', 'training_stats', 'preferences']) {
      _db
          .collection('users')
          .doc(uid)
          .collection(col)
          .doc('main')
          .snapshots()
          .listen((snap) async {
        if (!snap.exists) return;
        await _prefs.setString('cached_$col', jsonEncode(snap.data()));
        lastSync.value = DateTime.now();
        await _prefs.setString('last_sync', lastSync.value!.toIso8601String());
      });
    }
  }
}
