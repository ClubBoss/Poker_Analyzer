import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/user_goal.dart';
import 'cloud_retry_policy.dart';

class GoalSyncService {
  GoalSyncService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const _syncKey = 'goals_last_sync';

  String? get uid => _auth.currentUser?.uid;

  Future<bool> _online() async {
    final r = await Connectivity().checkConnectivity();
    return r != ConnectivityResult.none;
  }

  Future<void> upload(List<UserGoal> goals) async {
    if (uid == null || !await _online()) return;
    final col = _db.collection('users').doc(uid).collection('goals');
    final batch = _db.batch();
    final now = DateTime.now().toIso8601String();
    for (final g in goals) {
      final data = {
        'goalId': g.id,
        'title': g.title,
        'type': g.type,
        'target': g.target,
        'base': g.base,
        if (g.tag != null) 'tag': g.tag,
        if (g.targetAccuracy != null) 'targetAccuracy': g.targetAccuracy,
        'progress': null,
        'createdAt': g.createdAt.toIso8601String(),
        if (g.completedAt != null)
          'completedAt': g.completedAt!.toIso8601String(),
        'updatedAt': now,
      };
      batch.set(col.doc(g.id), data, SetOptions(merge: true));
    }
    await CloudRetryPolicy.execute(() => batch.commit());
    final prefs = await PreferencesService.getInstance();
    await prefs.setString(_syncKey, now);
  }

  Future<List<UserGoal>> download() async {
    if (uid == null || !await _online()) return [];
    final snap = await CloudRetryPolicy.execute(
      () => _db.collection('users').doc(uid).collection('goals').get(),
    );
    final result = <UserGoal>[];
    for (final d in snap.docs) {
      final data = d.data();
      result.add(
        UserGoal(
          id: data['goalId'] as String? ?? d.id,
          title: data['title'] as String? ?? '',
          type: data['type'] as String? ?? 'mistakes',
          target: (data['target'] as num?)?.toInt() ?? 1,
          base: (data['base'] as num?)?.toInt() ?? 0,
          createdAt:
              DateTime.tryParse(data['createdAt'] as String? ?? '') ??
              DateTime.now(),
          completedAt: data['completedAt'] != null
              ? DateTime.tryParse(data['completedAt'] as String)
              : null,
          tag: data['tag'] as String?,
          targetAccuracy: (data['targetAccuracy'] as num?)?.toDouble(),
        ),
      );
    }
    final prefs = await PreferencesService.getInstance();
    await prefs.setString(_syncKey, DateTime.now().toIso8601String());
    return result;
  }
}
