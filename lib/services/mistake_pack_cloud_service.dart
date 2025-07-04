import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        .get();
    return [
      for (final d in snap.docs)
        MistakePack.fromJson({...d.data(), 'id': d.id})
    ];
  }

  Future<void> savePack(MistakePack pack) async {
    if (_uid == null) return;
    await _db
        .collection('mistakes')
        .doc(_uid)
        .collection('packs')
        .doc(pack.id)
        .set(pack.toJson());
  }
}
