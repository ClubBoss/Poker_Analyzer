import 'dart:async';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../helpers/training_pack_storage.dart';
import '../models/v2/training_pack_template.dart';
import '../models/saved_hand.dart';
import 'saved_hand_manager_service.dart';
import 'saved_hand_stats_service.dart';
import 'session_log_service.dart';

class SuggestedPackService extends ChangeNotifier {
  static const _templateKey = 'suggested_weekly_pack';
  static const _dateKey = 'suggested_weekly_date';

  final SessionLogService logs;
  final SavedHandManagerService hands;
  final SavedHandStatsService stats;

  TrainingPackTemplate? _template;
  DateTime? _date;
  Timer? _timer;

  SuggestedPackService({
    required this.logs,
    required this.hands,
    required this.stats,
  });

  TrainingPackTemplate? get template => _template;
  DateTime? get date => _date;

  Future<void> load() async {
    final prefs = await PreferencesService.getInstance();
    final tplRaw = prefs.getString(_templateKey);
    final dateStr = prefs.getString(_dateKey);
    if (tplRaw != null) {
      try {
        _template =
            TrainingPackTemplate.fromJson(jsonDecode(tplRaw) as Map<String, dynamic>);
      } catch (_) {}
    }
    _date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    if (_date == null || DateTime.now().difference(_date!).inDays >= 7) {
      await _generate();
    }
    logs.addListener(_check);
    _schedule();
  }

  Future<void> _check() async {
    final now = DateTime.now();
    if (_date == null || now.difference(_date!).inDays >= 7) {
      await _generate();
    }
    _schedule();
  }

  Future<void> _generate() async {
    final cats = logs.getRecentMistakes();
    if (cats.isEmpty) return;
    final selected = <SavedHand>[];
    for (final e in cats.entries) {
      final list = stats.filterByCategory(e.key);
      for (final h in list) {
        selected.add(h);
        if (selected.length >= 10) break;
      }
      if (selected.length >= 10) break;
    }
    if (selected.isEmpty) return;
    final tpl = hands
        .createPack('Suggested Training', selected)
        .copyWith(id: 'suggested_weekly', createdAt: DateTime.now());
    final stored = await TrainingPackStorage.load();
    final idx = stored.indexWhere((t) => t.id == 'suggested_weekly');
    if (idx == -1) {
      stored.add(tpl);
    } else {
      stored[idx] = tpl;
    }
    await TrainingPackStorage.save(stored);
    _template = tpl;
    _date = DateTime.now();
    final prefs = await PreferencesService.getInstance();
    await prefs.setString(_templateKey, jsonEncode(tpl.toJson()));
    await prefs.setString(_dateKey, _date!.toIso8601String());
    notifyListeners();
  }

  void _schedule() {
    _timer?.cancel();
    if (_date == null) return;
    final next = _date!.add(const Duration(days: 7));
    _timer = Timer(next.difference(DateTime.now()), _check);
  }

  @override
  void dispose() {
    logs.removeListener(_check);
    _timer?.cancel();
    super.dispose();
  }
}
