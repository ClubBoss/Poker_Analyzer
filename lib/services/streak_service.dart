import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cloud_retry_policy.dart';

class StreakService extends ChangeNotifier {
  static const _countKey = 'training_streak_current';
  static const _lastKey = 'training_streak_last';
  final ValueNotifier<int> streak = ValueNotifier(0);
  DateTime? _last;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    streak.value = prefs.getInt(_countKey) ?? 0;
    final lastStr = prefs.getString(_lastKey);
    _last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    await _syncFromCloud();
    _checkReset();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_countKey, streak.value);
    if (_last != null) {
      await prefs.setString(_lastKey, _last!.toIso8601String());
    } else {
      await prefs.remove(_lastKey);
    }
  }

  Future<void> _syncFromCloud() async {
    if (_uid == null) return;
    try {
      await CloudRetryPolicy.execute<void>(() async {
        final doc = await _db.collection('stats').doc(_uid).collection('streak').doc('main').get();
        if (!doc.exists) return;
        final data = doc.data()!;
        streak.value = (data['currentStreak'] as num?)?.toInt() ?? streak.value;
        final ts = data['lastTrainingDate'] as String?;
        _last = ts != null ? DateTime.tryParse(ts) : _last;
        await _save();
      });
    } catch (_) {}
  }

  Future<void> _syncToCloud() async {
    if (_uid == null) return;
    try {
      await CloudRetryPolicy.execute(() => _db.collection('stats').doc(_uid).collection('streak').doc('main').set({
            'currentStreak': streak.value,
            'lastTrainingDate': _last?.toIso8601String(),
          }));
    } catch (_) {}
  }

  void _checkReset() {
    if (_last == null) return;
    final today = DateTime.now();
    final last = DateTime(_last!.year, _last!.month, _last!.day);
    if (today.difference(last).inDays > 1) {
      streak.value = 0;
    }
  }

  Future<void> recordTraining() async {
    final today = DateTime.now();
    final last = _last != null ? DateTime(_last!.year, _last!.month, _last!.day) : null;
    if (last == null) {
      streak.value = 1;
    } else {
      final diff = DateTime(today.year, today.month, today.day).difference(last).inDays;
      if (diff == 0) return;
      if (diff == 1) {
        streak.value += 1;
      } else {
        streak.value = 1;
      }
    }
    _last = DateTime(today.year, today.month, today.day);
    await _save();
    await _syncToCloud();
    notifyListeners();
  }
}
