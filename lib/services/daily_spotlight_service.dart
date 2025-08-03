import 'dart:async';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/v2/training_pack_template.dart';
import 'template_storage_service.dart';

class DailySpotlightService extends ChangeNotifier {
  static const _idKey = 'daily_spotlight_id';
  static const _dateKey = 'daily_spotlight_date';

  final TemplateStorageService templates;
  TrainingPackTemplate? _template;
  DateTime? _date;
  Timer? _timer;

  DailySpotlightService({required this.templates});

  TrainingPackTemplate? get template => _template;
  DateTime? get date => _date;

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
            orElse: () => TrainingPackTemplate(id: id, name: id),
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
    final list = templates.templates.where((t) => t.recommended).toList();
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
