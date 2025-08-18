import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'cloud_retry_policy.dart';

import '../models/mistake_pack.dart';

class MistakePackCloudService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<List<MistakePack>> loadPacks() async {
    if (_uid == null) return [];
    final snap = await _db
        .collection('mistakes')
        .doc(_uid)
        .collection('packs')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return [
      for (final d in snap.docs)
        MistakePack.fromJson({...d.data(), 'id': d.id}),
    ];
  }

  Future<void> savePack(MistakePack pack) async {
    if (_uid == null) return;
    await CloudRetryPolicy.execute(
      () => _db
          .collection('mistakes')
          .doc(_uid)
          .collection('packs')
          .doc(pack.id)
          .set(pack.toJson()),
    );
  }

  Future<void> deletePack(String id) async {
    if (_uid == null) return;
    await CloudRetryPolicy.execute(
      () => _db
          .collection('mistakes')
          .doc(_uid)
          .collection('packs')
          .doc(id)
          .delete(),
    );
  }

  Future<void> deleteOlderThan(DateTime cutoff) async {
    if (_uid == null) return;
    await CloudRetryPolicy.execute<void>(() async {
      final col = _db.collection('mistakes').doc(_uid).collection('packs');
      final snap = await col
          .where('createdAt', isLessThan: cutoff.toIso8601String())
          .get();
      final batch = _db.batch();
      for (final d in snap.docs) {
        batch.delete(col.doc(d.id));
      }
      await batch.commit();
    });
  }
}
