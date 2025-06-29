import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/training_pack.dart';
import 'training_pack_storage_service.dart';

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
    await storage.save();
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
      storage.save();
    });
    return _sub;
  }

  void cancelWatch() {
    _sub?.cancel();
    _sub = null;
  }
}
