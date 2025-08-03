import 'dart:async';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'template_storage_service.dart';
import 'training_pack_stats_service.dart';

class DailyPackService extends ChangeNotifier {
  static const _idKey = 'daily_pack_id';
  static const _dateKey = 'daily_pack_date';

  final TemplateStorageService templates;
  TrainingPackTemplateV2? _template;
  DateTime? _date;
  Timer? _timer;

  DailyPackService({required this.templates});

  TrainingPackTemplateV2? get template => _template;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> load() async {
    final prefs = await PreferencesService.getInstance();
    final id = prefs.getString(_idKey);
    final dateStr = prefs.getString(_dateKey);
    _date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    _template = id != null
        ? templates.templates.firstWhere(
            (t) => t.id == id,
            orElse: () => null,
          )
        : null;
    await ensureToday();
  }

  Future<void> ensureToday() async {
    final now = DateTime.now();
    if (_template != null && _date != null && _sameDay(_date!, now)) {
      _schedule();
      return;
    }
    final preferred = <TrainingPackTemplateV2>[];
    final others = <TrainingPackTemplateV2>[];
    for (final t in templates.templates) {
      final stat = await TrainingPackStatsService.getStats(t.id);
      final ev = stat == null ? 0.0 : (stat.postEvPct > 0 ? stat.postEvPct : stat.preEvPct);
      final icm = stat == null ? 0.0 : (stat.postIcmPct > 0 ? stat.postIcmPct : stat.preIcmPct);
      final completed = stat != null && stat.accuracy >= .9 && ev >= 80 && icm >= 80;
      if (completed || (ev >= 90 && icm >= 90)) continue;
      final target = (t.recommended || t.tags.contains('starter') ||
          now.difference(t.created).inDays < 7)
          ? preferred
          : others;
      target.add(t);
    }
    final list = preferred.isNotEmpty ? preferred : others;
    if (list.isEmpty) return;
    final tpl = list[Random().nextInt(list.length)];
    _template = tpl;
    _date = DateTime(now.year, now.month, now.day);
    final prefs = await PreferencesService.getInstance();
    await prefs.setString(_idKey, tpl.id);
    await prefs.setString(_dateKey, _date!.toIso8601String());
    _schedule();
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
    _timer?.cancel();
    super.dispose();
  }
}
