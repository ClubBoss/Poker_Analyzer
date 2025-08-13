import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/xp_entry.dart';
import 'cloud_retry_policy.dart';

class XPTrackerCloudService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<List<XPEntry>> loadEntries() async {
    if (_uid == null) return [];
    final snap = await CloudRetryPolicy.execute(() => _db
        .collection('users')
        .doc(_uid)
        .collection('xp')
        .orderBy('date', descending: true)
        .limit(100)
        .get());
    return [
      for (final d in snap.docs) XPEntry.fromJson({...d.data(), 'id': d.id})
    ];
  }

  Future<void> saveEntry(XPEntry e) async {
    if (_uid == null) return;
    await CloudRetryPolicy.execute(() => _db
        .collection('users')
        .doc(_uid)
        .collection('xp')
        .doc(e.id)
        .set(e.toJson()));
  }
}
