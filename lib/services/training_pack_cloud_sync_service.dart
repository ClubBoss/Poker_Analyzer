import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cloud_retry_policy.dart';

import '../models/training_pack.dart';
import '../models/training_pack_template_model.dart';
import '../services/training_pack_stats_service.dart';
import 'training_pack_storage_service.dart';
import 'training_pack_template_storage_service.dart';

class TrainingPackCloudSyncService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  StreamSubscription? _sub;
  final ValueNotifier<DateTime?> lastSync = ValueNotifier(null);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getString('pack_sync_ts');
    if (ts != null) lastSync.value = DateTime.tryParse(ts);
  }

  Future<List<TrainingPack>> loadPacks() async {
    if (_uid == null) return [];
    final snap = await _db
        .collection('users')
        .doc(_uid)
        .collection('training_packs')
        .get();
    return [
      for (final d in snap.docs)
        TrainingPack.fromJson({...d.data(), 'id': d.id}),
    ];
  }

  Future<void> savePack(TrainingPack pack) async {
    if (_uid == null) return;
    await _db
        .collection('users')
        .doc(_uid)
        .collection('training_packs')
        .doc(pack.id)
        .set(pack.toJson());
  }

  Future<void> deletePack(String id) async {
    if (_uid == null) return;
    await _db
        .collection('users')
        .doc(_uid)
        .collection('training_packs')
        .doc(id)
        .delete();
  }

  Future<void> syncUp(TrainingPackStorageService storage) async {
    if (_uid == null) return;
    await CloudRetryPolicy.execute<void>(() async {
      final col =
          _db.collection('users').doc(_uid).collection('training_packs');
      final batch = _db.batch();
      for (final p in storage.packs.where((e) => !e.isBuiltIn)) {
        batch.set(col.doc(p.id), p.toJson());
      }
      await batch.commit();
    });
    lastSync.value = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pack_sync_ts', lastSync.value!.toIso8601String());
  }

  Future<void> syncDown(TrainingPackStorageService storage) async {
    final remote = await loadPacks();
    storage.merge(remote);
    storage.notifyListeners();
    storage.schedulePersist();
    lastSync.value = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pack_sync_ts', lastSync.value!.toIso8601String());
  }

  StreamSubscription? watch(TrainingPackStorageService storage) {
    _sub?.cancel();
    if (_uid == null) return null;
    _sub = _db
        .collection('users')
        .doc(_uid)
        .collection('training_packs')
        .snapshots()
        .listen((snap) {
      final list = [
        for (final d in snap.docs)
          TrainingPack.fromJson({...d.data(), 'id': d.id}),
      ];
      storage.merge(list);
      storage.notifyListeners();
      storage.schedulePersist();
    });
    return _sub;
  }

  void cancelWatch() {
    _sub?.cancel();
    _sub = null;
  }

  Future<List<TrainingPackTemplateModel>> loadTemplates() async {
    if (_uid == null) return [];
    final snap =
        await _db.collection('packs').doc(_uid).collection('templates').get();
    return [
      for (final d in snap.docs)
        TrainingPackTemplateModel.fromJson({...d.data(), 'id': d.id}),
    ];
  }

  Future<List<TrainingPackTemplateModel>> loadPublicTemplates() async {
    final snap = await _db.collection('public_templates').get();
    return [
      for (final d in snap.docs)
        TrainingPackTemplateModel.fromJson({...d.data(), 'id': d.id}),
    ];
  }

  Future<void> saveTemplate(TrainingPackTemplateModel tpl) async {
    if (_uid == null) return;
    await _db
        .collection('packs')
        .doc(_uid)
        .collection('templates')
        .doc(tpl.id)
        .set(tpl.toJson());
  }

  Future<void> deleteTemplate(String id) async {
    if (_uid == null) return;
    await _db
        .collection('packs')
        .doc(_uid)
        .collection('templates')
        .doc(id)
        .delete();
  }

  Future<void> syncDownTemplates(
    TrainingPackTemplateStorageService storage,
  ) async {
    final remote = await loadTemplates();
    storage.merge(remote);
    await storage.saveAll();
    lastSync.value = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pack_sync_ts', lastSync.value!.toIso8601String());
  }

  Future<void> syncUpTemplates(
    TrainingPackTemplateStorageService storage,
  ) async {
    if (_uid == null) return;
    await CloudRetryPolicy.execute<void>(() async {
      final col = _db.collection('packs').doc(_uid).collection('templates');
      final batch = _db.batch();
      for (final t in storage.templates) {
        batch.set(col.doc(t.id), t.toJson());
      }
      await batch.commit();
    });
    await syncUpStats();
    lastSync.value = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pack_sync_ts', lastSync.value!.toIso8601String());
  }

  Future<Map<String, TrainingPackStat>> loadStats() async {
    if (_uid == null) return {};
    final snap =
        await _db.collection('packs').doc(_uid).collection('stats').get();
    return {
      for (final d in snap.docs) d.id: TrainingPackStat.fromJson(d.data()),
    };
  }

  Future<Map<String, TrainingPackStat>> _localStats() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, TrainingPackStat>{};
    for (final k in prefs.getKeys()) {
      if (!k.startsWith('tpl_stat_')) continue;
      final raw = prefs.getString(k);
      if (raw == null) continue;
      try {
        final data = jsonDecode(raw);
        if (data is Map<String, dynamic>) {
          map[k.substring(9)] = TrainingPackStat.fromJson(data);
        }
      } catch (_) {}
    }
    return map;
  }

  Future<void> _saveLocalStats(Map<String, TrainingPackStat> stats) async {
    final prefs = await SharedPreferences.getInstance();
    for (final e in stats.entries) {
      await prefs.setString('tpl_stat_${e.key}', jsonEncode(e.value.toJson()));
    }
  }

  Future<void> syncDownStats() async {
    final remote = await loadStats();
    final local = await _localStats();
    for (final e in remote.entries) {
      final l = local[e.key];
      if (l == null || e.value.last.isAfter(l.last)) {
        local[e.key] = e.value;
      }
    }
    await _saveLocalStats(local);
    lastSync.value = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pack_sync_ts', lastSync.value!.toIso8601String());
  }

  Future<void> syncUpStats() async {
    if (_uid == null) return;
    final stats = await _localStats();
    await CloudRetryPolicy.execute<void>(() async {
      final col = _db.collection('packs').doc(_uid).collection('stats');
      final batch = _db.batch();
      for (final e in stats.entries) {
        batch.set(col.doc(e.key), e.value.toJson());
      }
      await batch.commit();
    });
  }
}
