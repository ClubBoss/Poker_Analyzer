import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'cloud_retry_policy.dart';
import 'training_stats_service.dart';

class MistakeHistorySyncService {
  final FirebaseFirestore _db;
  final String? _uid;

  MistakeHistorySyncService({FirebaseFirestore? firestore, String? uid})
      : _db = firestore ?? FirebaseFirestore.instance,
        _uid = uid ?? FirebaseAuth.instance.currentUser?.uid;

  Future<void> uploadMistakes(Map<String, int> mistakeCounts) async {
    if (_uid == null) return;
    await CloudRetryPolicy.execute(
      () => _db.collection('mistakeHistory').doc(_uid).set({
        'counts': mistakeCounts,
        'updatedAt': DateTime.now().toIso8601String(),
      }),
    );
  }

  Future<Map<String, int>> downloadMistakes() async {
    if (_uid == null) return {};
    final snap = await CloudRetryPolicy.execute(
      () => _db.collection('mistakeHistory').doc(_uid).get(),
    );
    if (!snap.exists) return {};
    final data = snap.data();
    final result = <String, int>{};
    final counts = data?['counts'];
    if (counts is Map) {
      counts.forEach((key, value) {
        result[key.toString()] = (value as num).toInt();
      });
    }
    return result;
  }

  Future<void> sync() async {
    final local = TrainingStatsService.instance?.mistakeCounts ?? {};
    final remote = await downloadMistakes();
    final merged = <String, int>{};
    for (final key in {...local.keys, ...remote.keys}) {
      final lv = local[key] ?? 0;
      final rv = remote[key] ?? 0;
      merged[key] = lv > rv ? lv : rv;
    }
    await TrainingStatsService.instance?.overwriteMistakeCounts(merged);
    await uploadMistakes(merged);
  }
}
