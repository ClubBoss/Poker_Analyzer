import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'cloud_retry_policy.dart';

import '../models/training_pack.dart';
import '../models/training_pack_template_model.dart';
import 'training_pack_storage_service.dart';
import 'training_pack_template_storage_service.dart';

class TrainingPackCloudSyncService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  StreamSubscription? _sub;

  Future<List<TrainingPack>> loadPacks() async {
    if (_uid == null) return [];
    final snap = await _db
        .collection('users')
        .doc(_uid)
        .collection('training_packs')
        .get();
    return [
      for (final d in snap.docs)
        TrainingPack.fromJson({...d.data(), 'id': d.id})
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

  Future<void> syncDown(TrainingPackStorageService storage) async {
    final remote = await loadPacks();
    storage.merge(remote);
    storage.notifyListeners();
    storage.schedulePersist();
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
          TrainingPack.fromJson({...d.data(), 'id': d.id})
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
    final snap = await _db
        .collection('packs')
        .doc(_uid)
        .collection('templates')
        .get();
    return [
      for (final d in snap.docs)
        TrainingPackTemplateModel.fromJson({...d.data(), 'id': d.id})
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
      TrainingPackTemplateStorageService storage) async {
    final remote = await loadTemplates();
    storage.merge(remote);
    await storage.saveAll();
  }

  Future<void> syncUpTemplates(TrainingPackTemplateStorageService storage) async {
    if (_uid == null) return;
    await CloudRetryPolicy.execute<void>(() async {
      final col = _db.collection('packs').doc(_uid).collection('templates');
      final batch = _db.batch();
      for (final t in storage.templates) {
        batch.set(col.doc(t.id), t.toJson());
      }
      await batch.commit();
    });
  }
}
