import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'training_stats_service.dart';
import 'streak_service.dart';
import 'goals_service.dart';
import 'user_action_logger.dart';

class CloudBackupService extends ChangeNotifier {
  final TrainingStatsService stats;
  final StreakService streak;
  final GoalsService goals;
  final UserActionLogger log;

  CloudBackupService({
    required this.stats,
    required this.streak,
    required this.goals,
    required this.log,
  });

  late final CollectionReference<Map<String, dynamic>> _ref;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _statsSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _streakSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _goalsSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _logSub;

  Future<void> load() async {
    await FirebaseAuth.instance.signInAnonymously();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _ref = FirebaseFirestore.instance.collection('users').doc(uid).collection('backup');
    _listen();
    await syncNow();
  }

  void _listen() {
    _statsSub = _ref.doc('stats').snapshots().listen((snap) {
      final data = snap.data();
      if (data != null) stats.applyMap(data);
    });
    _streakSub = _ref.doc('streak').snapshots().listen((snap) {
      final data = snap.data();
      if (data != null) streak.applyMap(data);
    });
    _goalsSub = _ref.doc('goals').snapshots().listen((snap) {
      final data = snap.data();
      if (data != null) goals.applyMap(data);
    });
    _logSub = _ref.doc('user_action_log').snapshots().listen((snap) {
      final data = snap.data();
      if (data != null) log.applyMap(data);
    });
    stats.addListener(_pushStats);
    streak.addListener(_pushStreak);
    goals.addListener(_pushGoals);
    log.addListener(_pushLog);
  }

  Future<void> _pushStats() => _ref.doc('stats').set(stats.toMap(), SetOptions(merge: true));
  Future<void> _pushStreak() => _ref.doc('streak').set(streak.toMap(), SetOptions(merge: true));
  Future<void> _pushGoals() => _ref.doc('goals').set(goals.toMap(), SetOptions(merge: true));
  Future<void> _pushLog() => _ref.doc('user_action_log').set(log.toMap(), SetOptions(merge: true));

  Future<void> syncNow() async {
    await Future.wait([
      _pushStats(),
      _pushStreak(),
      _pushGoals(),
      _pushLog(),
    ]);
  }

  @override
  void dispose() {
    _statsSub?.cancel();
    _streakSub?.cancel();
    _goalsSub?.cancel();
    _logSub?.cancel();
    stats.removeListener(_pushStats);
    streak.removeListener(_pushStreak);
    goals.removeListener(_pushGoals);
    log.removeListener(_pushLog);
    super.dispose();
  }
}
