import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_hand.dart';
import 'training_stats_service.dart';
import 'saved_hand_manager_service.dart';

class DailyGoalsService extends ChangeNotifier {
  static const _dateKey = 'daily_goals_date';
  static const _targetsKey = 'daily_goals_targets';
  static const _baseSessionsKey = 'daily_goals_base_sessions';

  final TrainingStatsService stats;
  final SavedHandManagerService hands;

  DateTime? _date;
  int _baseSessions = 0;
  double targetSessions = 0;
  double targetAccuracy = 0;
  double targetEv = 0;
  double targetIcm = 0;

  Timer? _timer;

  DailyGoalsService({required this.stats, required this.hands});

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_dateKey);
    _date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    final raw = prefs.getString(_targetsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        targetSessions = (data['sessions'] as num?)?.toDouble() ?? 0;
        targetAccuracy = (data['accuracy'] as num?)?.toDouble() ?? 0;
        targetEv = (data['ev'] as num?)?.toDouble() ?? 0;
        targetIcm = (data['icm'] as num?)?.toDouble() ?? 0;
      } catch (_) {}
    }
    _baseSessions = prefs.getInt(_baseSessionsKey) ?? stats.sessionsCompleted;
    await _ensureToday();
    stats.sessionsStream.listen((_) => notifyListeners());
    hands.addListener(notifyListeners);
    _schedule();
    notifyListeners();
  }

  List<SavedHand> _handsSince(DateTime start) {
    final end = start.add(const Duration(days: 1));
    return [
      for (final h in hands.hands)
        if (!h.date.isBefore(start) && h.date.isBefore(end)) h,
    ];
  }

  List<SavedHand> _recentHands(int days) {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days));
    return [
      for (final h in hands.hands)
        if (!h.date.isBefore(start)) h,
    ];
  }

  double _calcAccuracy(List<SavedHand> list) {
    int total = 0;
    int correct = 0;
    for (final h in list) {
      final exp = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      if (exp == null || gto == null) continue;
      total++;
      if (exp == gto) correct++;
    }
    return total > 0 ? correct / total * 100 : 0;
  }

  double _calcEv(List<SavedHand> list) {
    final vals = [
      for (final h in list)
        if (h.heroEv != null) h.heroEv!,
    ];
    if (vals.isEmpty) return 0;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  double _calcIcm(List<SavedHand> list) {
    final vals = [
      for (final h in list)
        if (h.heroIcmEv != null) h.heroIcmEv!,
    ];
    if (vals.isEmpty) return 0;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  Future<void> _ensureToday() async {
    final now = DateTime.now();
    if (_date != null &&
        _date!.year == now.year &&
        _date!.month == now.month &&
        _date!.day == now.day) {
      return;
    }
    final recent = _recentHands(7);
    final sessions = stats.sessionsDaily(7);
    final avgSessions = sessions.isNotEmpty
        ? sessions.map((e) => e.value).reduce((a, b) => a + b) / sessions.length
        : 0;
    targetSessions = (avgSessions + 1).roundToDouble();
    targetAccuracy = (_calcAccuracy(recent) + 5).clamp(50, 100);
    targetEv = _calcEv(recent) + 0.1;
    targetIcm = _calcIcm(recent) + 0.1;
    _baseSessions = stats.sessionsCompleted;
    _date = DateTime(now.year, now.month, now.day);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateKey, _date!.toIso8601String());
    await prefs.setInt(_baseSessionsKey, _baseSessions);
    await prefs.setString(
      _targetsKey,
      jsonEncode({
        'sessions': targetSessions,
        'accuracy': targetAccuracy,
        'ev': targetEv,
        'icm': targetIcm,
      }),
    );
  }

  void _schedule() {
    _timer?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _timer = Timer(next.difference(now), () async {
      await _ensureToday();
      _schedule();
      notifyListeners();
    });
  }

  int get progressSessions => stats.sessionsCompleted - _baseSessions;
  double get progressAccuracy => _calcAccuracy(
    _handsSince(
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    ),
  );
  double get progressEv => _calcEv(
    _handsSince(
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    ),
  );
  double get progressIcm => _calcIcm(
    _handsSince(
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    ),
  );

  bool get anyIncomplete =>
      progressSessions < targetSessions ||
      progressAccuracy < targetAccuracy ||
      progressEv < targetEv ||
      progressIcm < targetIcm;

  @override
  void dispose() {
    _timer?.cancel();
    hands.removeListener(notifyListeners);
    super.dispose();
  }
}
