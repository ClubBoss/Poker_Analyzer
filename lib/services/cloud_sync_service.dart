import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'cloud_retry_policy.dart';
import '../models/saved_hand.dart';
import '../models/session_log.dart';
import 'pack_launch_history_sync_service.dart';
import 'mistake_history_sync_service.dart';

class CloudSyncService {
  CloudSyncService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  static const _cols = [
    'training_spots',
    'training_stats',
    'xp_history',
    'preferences',
    'saved_hands',
    'session_notes',
    'session_logs',
    'pinned_sessions',
    'evaluation_queue',
  ];

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  late SharedPreferences _prefs;
  Box? _box;
  static bool get isLocal =>
      kIsWeb ||
      (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.linux ||
              defaultTargetPlatform == TargetPlatform.macOS));
  bool get _local => CloudSyncService.isLocal;
  String? get uid => _auth.currentUser?.uid;
  bool get isEnabled => uid != null;
  final List<Map<String, dynamic>> _pending = [];
  final ValueNotifier<DateTime?> lastSync = ValueNotifier(null);
  final ValueNotifier<double> progress = ValueNotifier(0);
  final ValueNotifier<String?> syncMessage = ValueNotifier(null);
  late final Connectivity _conn;
  StreamSubscription<ConnectivityResult>? _connSub;

  void _notify(String message) {
    syncMessage.value = message;
    Future.delayed(const Duration(seconds: 3), () {
      if (syncMessage.value == message) syncMessage.value = null;
    });
  }

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
    _conn = Connectivity();
    _connSub = _conn.onConnectivityChanged.listen((r) async {
      if (r != ConnectivityResult.none && _pending.isNotEmpty) await syncUp();
      if (r != ConnectivityResult.none &&
          (lastSync.value == null ||
              DateTime.now().difference(lastSync.value!) >
                  const Duration(hours: 6))) {
        await syncDown();
      }
    });

    await PackLaunchHistorySyncService(uid: uid).sync();
    await MistakeHistorySyncService(uid: uid).sync();
  }

  Future<void> syncUp() async {
    if (_pending.isEmpty || uid == null) return;
    progress.value = 1;
    if (_local) {
      for (final m in _pending) {
        _box!.put('${m['col']}_${m['id']}', m['data']);
        _box!.put('cached_${m['col']}', m['data']);
      }
      _pending.clear();
      await _box!.put('pending_mutations', _pending);
      lastSync.value = DateTime.now();
      await _box!.put('last_sync', lastSync.value!.toIso8601String());
      _notify('Synced changes to cloud');
      return;
    }
    final user = _db.collection('users').doc(uid);
    final batch = _db.batch();
    for (final m in _pending) {
      final ref = user.collection(m['col'] as String).doc(m['id'] as String);
      batch.set(
        ref,
        m['data'] as Map<String, dynamic>,
        SetOptions(merge: true),
      );
    }
    try {
      await batch.commit();
      _pending.clear();
      await _prefs.setStringList('pending_mutations', []);
      lastSync.value = DateTime.now();
      await _prefs.setString('last_sync', lastSync.value!.toIso8601String());
    } catch (_) {
      progress.value = -1;
      return;
    }
    progress.value = 0;
    _notify('Synced changes to cloud');
  }

  Future<void> syncDown() async {
    if (uid == null) return;
    progress.value = 1;
    if (_local) {
      final ts = _box!.get('last_sync') as String?;
      if (ts != null) lastSync.value = DateTime.tryParse(ts);
      progress.value = 0;
      _notify('Loaded latest from cloud');
      return;
    }
    try {
      await CloudRetryPolicy.execute<void>(() async {
        final user = _db.collection('users').doc(uid);
        final futures = [
          for (final c in _cols) user.collection(c).doc('main').get(),
        ];
        final snaps = await Future.wait(futures);
        for (var i = 0; i < snaps.length; i++) {
          final col = _cols[i];
          final snap = snaps[i];
          if (!snap.exists) continue;
          final remote = snap.data()!;
          final localStr = _prefs.getString('cached_$col');
          final local = localStr != null
              ? jsonDecode(localStr) as Map<String, dynamic>
              : null;
          final remoteAt =
              DateTime.tryParse(remote['updatedAt'] as String? ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final localAt =
              DateTime.tryParse(local?['updatedAt'] as String? ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          if (remoteAt.isAfter(localAt)) {
            await _prefs.setString('cached_$col', jsonEncode(remote));
          }
        }
        final ts = _prefs.getString('last_sync');
        if (ts != null) lastSync.value = DateTime.tryParse(ts);
      });
    } catch (_) {
      progress.value = -1;
      return;
    }
    progress.value = 0;
    _notify('Loaded latest from cloud');
  }

  Future<void> queueMutation(
    String col,
    String id,
    Map<String, dynamic> data,
  ) async {
    _pending.removeWhere((e) => e['col'] == col && e['id'] == id);
    _pending.add({'col': col, 'id': id, 'data': data});
    if (_local) {
      await _box!.put('pending_mutations', _pending);
      await _box!.put('cached_$col', data);
    } else {
      await _prefs.setStringList(
        'pending_mutations',
        _pending.map(jsonEncode).toList(),
      );
      await _prefs.setString('cached_$col', jsonEncode(data));
    }
  }

  Map<String, dynamic>? getCached(String col) {
    if (_local) {
      final val = _box!.get('cached_$col');
      if (val is Map) return Map<String, dynamic>.from(val);
      if (val is String) return jsonDecode(val) as Map<String, dynamic>;
      return null;
    }
    final str = _prefs.getString('cached_$col');
    return str != null ? jsonDecode(str) as Map<String, dynamic> : null;
  }

  void watchChanges() {
    if (_local || uid == null) return;
    for (final col in _cols) {
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
            await _prefs.setString(
              'last_sync',
              lastSync.value!.toIso8601String(),
            );
          });
    }
  }

  void dispose() {
    _connSub?.cancel();
  }

  Future<void> save(String key, String value) async {
    if (_local) {
      await _box!.put(key, value);
      return;
    }
    await _prefs.setString(key, value);
    if (uid == null) return;
    await CloudRetryPolicy.execute(
      () => _db.collection('users').doc(uid).collection('prefs').doc(key).set({
        'v': value,
      }),
    );
  }

  Future<String?> load(String key) async {
    if (_local) {
      final val = _box!.get(key);
      if (val is String) return val;
      return null;
    }
    final local = _prefs.getString(key);
    if (uid == null) return local;
    try {
      final snap = await CloudRetryPolicy.execute(
        () =>
            _db.collection('users').doc(uid).collection('prefs').doc(key).get(),
      );
      final data = snap.data();
      if (data != null && data['v'] is String) {
        final v = data['v'] as String;
        await _prefs.setString(key, v);
        return v;
      }
    } catch (_) {}
    return local;
  }

  Future<void> uploadHands(List<SavedHand> hands) async {
    await queueMutation('saved_hands', 'main', {
      'hands': [for (final h in hands) h.toJson()],
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await syncUp();
  }

  Future<List<SavedHand>> downloadHands() async {
    if (uid == null) return [];
    final snap = await CloudRetryPolicy.execute(
      () => _db
          .collection('users')
          .doc(uid)
          .collection('saved_hands')
          .doc('main')
          .get(),
    );
    if (!snap.exists) return [];
    final data = snap.data();
    final list = data?['hands'];
    if (list is List) {
      return [
        for (final e in list)
          if (e is Map) SavedHand.fromJson(Map<String, dynamic>.from(e)),
      ];
    }
    return [];
  }

  Future<List<SavedHand>> loadHands() async {
    final cached = getCached('saved_hands');
    var hands = <SavedHand>[];
    var localAt = DateTime.fromMillisecondsSinceEpoch(0);
    if (cached != null) {
      final list = cached['hands'];
      if (list is List) {
        hands = [
          for (final e in list)
            if (e is Map) SavedHand.fromJson(Map<String, dynamic>.from(e)),
        ];
      }
      localAt =
          DateTime.tryParse(cached['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }
    if (uid == null) return hands;
    final snap = await CloudRetryPolicy.execute(
      () => _db
          .collection('users')
          .doc(uid)
          .collection('saved_hands')
          .doc('main')
          .get(),
    );
    if (snap.exists) {
      final remote = snap.data()!;
      final remoteAt =
          DateTime.tryParse(remote['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      if (remoteAt.isAfter(localAt)) {
        final list = remote['hands'];
        if (list is List) {
          hands = [
            for (final e in list)
              if (e is Map) SavedHand.fromJson(Map<String, dynamic>.from(e)),
          ];
          if (_local) {
            await _box!.put('cached_saved_hands', remote);
          } else {
            await _prefs.setString('cached_saved_hands', jsonEncode(remote));
          }
        }
      } else if (localAt.isAfter(remoteAt)) {
        await uploadHands(hands);
      }
    }
    return hands;
  }

  Future<void> uploadSessionNotes(Map<int, String> notes) async {
    await queueMutation('session_notes', 'main', {
      'notes': {for (final e in notes.entries) e.key.toString(): e.value},
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await syncUp();
  }

  Future<Map<int, String>> downloadSessionNotes() async {
    if (uid == null) return {};
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('session_notes')
        .doc('main')
        .get();
    if (!snap.exists) return {};
    final data = snap.data();
    final map = <int, String>{};
    if (data?['notes'] is Map) {
      (data!['notes'] as Map).forEach((k, v) {
        map[int.parse(k as String)] = v as String;
      });
    }
    return map;
  }

  Future<void> uploadSessionLogs(List<SessionLog> logs) async {
    await queueMutation('session_logs', 'main', {
      'logs': [for (final l in logs) l.toJson()],
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await syncUp();
  }

  Future<List<SessionLog>> downloadSessionLogs() async {
    if (uid == null) return [];
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('session_logs')
        .doc('main')
        .get();
    if (!snap.exists) return [];
    final data = snap.data();
    final list = data?['logs'];
    if (list is List) {
      return [
        for (final e in list)
          if (e is Map) SessionLog.fromJson(Map<String, dynamic>.from(e)),
      ];
    }
    return [];
  }

  Future<void> uploadPinned(Set<int> ids) async {
    await queueMutation('pinned_sessions', 'main', {
      'ids': [for (final i in ids) i],
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await syncUp();
  }

  Future<Set<int>> downloadPinned() async {
    if (uid == null) return {};
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('pinned_sessions')
        .doc('main')
        .get();
    if (!snap.exists) return {};
    final data = snap.data();
    final list = data?['ids'];
    if (list is List) return {for (final i in list) (i as num).toInt()};
    return {};
  }

  Future<void> uploadQueue(Map<String, dynamic> queue) async {
    await queueMutation('evaluation_queue', 'main', {
      ...queue,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await syncUp();
  }

  Future<Map<String, dynamic>?> downloadQueue() async {
    if (uid == null) return null;
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('evaluation_queue')
        .doc('main')
        .get();
    if (!snap.exists) return null;
    return snap.data();
  }

  Future<void> uploadTrainingStats(Map<String, dynamic> stats) async {
    await queueMutation('training_stats', 'main', stats);
    await syncUp();
  }

  Future<Map<String, dynamic>?> downloadTrainingStats() async {
    if (uid == null) return null;
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('training_stats')
        .doc('main')
        .get();
    if (!snap.exists) return null;
    return snap.data();
  }

  Future<void> uploadXp(Map<String, dynamic> data) async {
    await queueMutation('xp_history', 'main', data);
    await syncUp();
  }

  Future<Map<String, dynamic>?> downloadXp() async {
    if (uid == null) return null;
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('xp_history')
        .doc('main')
        .get();
    if (!snap.exists) return null;
    return snap.data();
  }
}
