import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/v2/training_pack_template.dart';
import 'adaptive_training_service.dart';
import 'template_storage_service.dart';
import 'xp_tracker_service.dart';

class DailyChallengeService extends ChangeNotifier {
  static const _idKey = 'daily_challenge_id';
  static const _dateKey = 'daily_challenge_date';
  static const _rewardKey = 'daily_challenge_rewarded';
  static const _rewardXp = 20;

  final AdaptiveTrainingService adaptive;
  final TemplateStorageService templates;
  final XPTrackerService xp;

  TrainingPackTemplate? _template;
  DateTime? _date;
  bool _rewarded = false;
  Timer? _timer;

  DailyChallengeService({
    required this.adaptive,
    required this.templates,
    required this.xp,
  });

  TrainingPackTemplate? get template => _template;
  bool get rewarded => _rewarded;
  DateTime? get date => _date;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_idKey);
    final dateStr = prefs.getString(_dateKey);
    _rewarded = prefs.getBool(_rewardKey) ?? false;
    _date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    _template = id != null
        ? templates.templates.firstWhere(
            (t) => t.id == id,
            orElse: () => TrainingPackTemplate(id: id, name: id),
          )
        : null;
    await ensureToday();
    xp.addListener(_check);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> ensureToday() async {
    final now = DateTime.now();
    if (_date != null && _template != null && _isSameDay(_date!, now)) {
      _schedule();
      await _check();
      return;
    }
    await adaptive.refresh();
    final list = adaptive.recommended;
    if (list.isEmpty) return;
    final tpl = list.first;
    _template = tpl;
    _date = DateTime(now.year, now.month, now.day);
    _rewarded = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_idKey, tpl.id);
    await prefs.setString(_dateKey, _date!.toIso8601String());
    await prefs.setBool(_rewardKey, false);
    _schedule();
    notifyListeners();
    await _check();
  }

  Future<void> _check() async {
    final tpl = _template;
    if (tpl == null || _rewarded) return;
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('completed_tpl_${tpl.id}') ?? false;
    if (!done) return;
    _rewarded = true;
    await prefs.setBool(_rewardKey, true);
    await xp.add(xp: _rewardXp, source: 'daily_challenge');
    notifyListeners();
  }

  void _schedule() {
    _timer?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _timer = Timer(next.difference(now), ensureToday);
  }

  @override
  void dispose() {
    xp.removeListener(_check);
    _timer?.cancel();
    super.dispose();
  }
}
