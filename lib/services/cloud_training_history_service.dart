import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/result_entry.dart';
import '../models/cloud_training_session.dart';

class CloudTrainingHistoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> saveSession(List<ResultEntry> results) async {
    if (_uid == null) return;
    final data = CloudTrainingSession(path: '', date: DateTime.now(), results: results).toJson();
    await _db
        .collection('users')
        .doc(_uid)
        .collection('training_sessions')
        .add(data);
  }

  Future<List<CloudTrainingSession>> loadSessions() async {
    if (_uid == null) return [];
    final snap = await _db
        .collection('users')
        .doc(_uid)
        .collection('training_sessions')
        .orderBy('date', descending: true)
        .get();
    return [
      for (final d in snap.docs)
        CloudTrainingSession.fromJson(d.data(), path: d.id)
    ];
  }

  Future<void> deleteSession(String id) async {
    if (_uid == null) return;
    await _db
        .collection('users')
        .doc(_uid)
        .collection('training_sessions')
        .doc(id)
        .delete();
  }

  Future<void> updateSession(String id, Map<String, dynamic> data) async {
    if (_uid == null) return;
    await _db
        .collection('users')
        .doc(_uid)
        .collection('training_sessions')
        .doc(id)
        .set(data, SetOptions(merge: true));
  }
}
