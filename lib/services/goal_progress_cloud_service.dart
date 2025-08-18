import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'cloud_retry_policy.dart';

class GoalProgressCloudService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<List<Map<String, dynamic>>> loadGoals() async {
    if (_uid == null) return [];
    final snap = await _db
        .collection('progress')
        .doc(_uid)
        .collection('goals')
        .get();
    return [for (final d in snap.docs) d.data()];
  }

  Future<void> saveProgress(Map<String, dynamic> data) async {
    if (_uid == null) return;
    final id = '${data['templateId']}_${data['goal']}'.replaceAll('/', '_');
    await CloudRetryPolicy.execute(
      () => _db
          .collection('progress')
          .doc(_uid)
          .collection('goals')
          .doc(id)
          .set(data),
    );
  }
}
