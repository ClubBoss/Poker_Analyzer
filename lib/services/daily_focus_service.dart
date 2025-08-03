import 'package:flutter/foundation.dart';
import 'package:poker_analyzer/services/preferences_service.dart';

import '../models/v2/hero_position.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'pack_generator_service.dart';
import 'training_pack_template_builder.dart';
import 'tag_mastery_service.dart';
import 'streak_service.dart';

class DailyFocusService extends ChangeNotifier {
  static const _dateKey = 'daily_focus_date';
  static const _tagKey = 'daily_focus_tag';

  final TagMasteryService mastery;
  final StreakService streak;

  String? _tag;
  DateTime? _date;

  DailyFocusService({required this.mastery, required this.streak});

  String? get tag => _tag;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> load() async {
    final prefs = await PreferencesService.getInstance();
    final dateStr = prefs.getString(_dateKey);
    _date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    _tag = prefs.getString(_tagKey);
    await ensureToday();
    streak.streak.addListener(ensureToday);
  }

  Future<void> ensureToday() async {
    final now = DateTime.now();
    if (_date != null && _sameDay(_date!, now)) return;
    _date = DateTime(now.year, now.month, now.day);
    if (streak.streak.value == 0) {
      _tag = null;
    } else {
      final map = await mastery.computeMastery();
      if (map.isNotEmpty) {
        final list = map.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));
        _tag = list.first.key;
      } else {
        _tag = null;
      }
    }
    final prefs = await PreferencesService.getInstance();
    await prefs.setString(_dateKey, _date!.toIso8601String());
    if (_tag != null) {
      await prefs.setString(_tagKey, _tag!);
    } else {
      await prefs.remove(_tagKey);
    }
    notifyListeners();
  }

  Future<TrainingPackTemplateV2?> buildPack() async {
    if (_tag == null) {
      return PackGeneratorService.generatePushFoldPack(
        id: 'daily_focus_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Daily Focus',
        heroBbStack: 10,
        playerStacksBb: const [10, 10],
        heroPos: HeroPosition.sb,
        heroRange: PackGeneratorService.topNHands(25).toList(),
      );
    }
    const builder = TrainingPackTemplateBuilder();
    return builder.buildWeaknessPack(mastery);
  }
}
