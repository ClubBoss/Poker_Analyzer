import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/training_pack.dart';
import 'training_pack_storage_service.dart';

class TrainingPackCloudSyncService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

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
}
