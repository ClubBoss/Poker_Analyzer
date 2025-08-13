import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'cloud_retry_policy.dart';

class CloudPreferencesService {
  CloudPreferencesService._();
  static final CloudPreferencesService instance = CloudPreferencesService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<bool?> getBool(String key) async {
    if (_uid == null) return null;
    try {
      final snap = await _db
          .collection('users')
          .doc(_uid)
          .collection('preferences')
          .doc('main')
          .get();
      final data = snap.data();
      return data?[key] as bool?;
    } catch (_) {
      return null;
    }
  }

  Future<void> setBool(String key, bool value) async {
    if (_uid == null) return;
    await CloudRetryPolicy.execute(() async {
      await _db
          .collection('users')
          .doc(_uid)
          .collection('preferences')
          .doc('main')
          .set({
        key: value,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    });
  }
}
