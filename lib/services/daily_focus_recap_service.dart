import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/v2/hero_position.dart';
import '../models/saved_hand.dart';
import '../models/v2/training_pack_template.dart';
import 'saved_hand_manager_service.dart';
import 'weak_spot_recommendation_service.dart';

class _PosStats {
  final int hands;
  final int correct;
  final double ev;
  final double icm;
  const _PosStats({
    this.hands = 0,
    this.correct = 0,
    this.ev = 0,
    this.icm = 0,
  });
  double get accuracy => hands > 0 ? correct / hands : 0;
}

class DailyFocusRecapService extends ChangeNotifier {
  static const _dateKey = 'focus_recap_date';
  static const _summaryKey = 'focus_recap_summary';
  static const _focusKey = 'focus_recap_focus';
  static const _shownKey = 'focus_recap_shown';

  final SavedHandManagerService hands;
  final WeakSpotRecommendationService weak;

  DateTime? _date;
  String _summary = '';
  HeroPosition? _focus;
  bool _shown = false;

  DailyFocusRecapService({required this.hands, required this.weak});

  String get summary => _summary;
  HeroPosition? get focus => _focus;
  bool get show => !_shown && _summary.isNotEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_dateKey);
    _date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    final focusStr = prefs.getString(_focusKey);
    _focus = focusStr != null
        ? HeroPosition.values.firstWhere(
            (e) => e.name == focusStr,
            orElse: () => HeroPosition.unknown,
          )
        : null;
    _summary = prefs.getString(_summaryKey) ?? '';
    _shown = prefs.getString(_shownKey) == dateStr && dateStr != null;
    await _ensureToday();
    hands.addListener(_ensureToday);
  }

  Future<void> markShown() async {
    _shown = true;
    await _save();
    notifyListeners();
  }

  Future<TrainingPackTemplate?> recommendedPack() =>
      focus == null ? Future.value(null) : weak.buildPack(focus!);

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    if (_date != null)
      await prefs.setString(_dateKey, _date!.toIso8601String());
    if (_focus != null) await prefs.setString(_focusKey, _focus!.name);
    await prefs.setString(_summaryKey, _summary);
    if (_shown && _date != null) {
      await prefs.setString(_shownKey, _date!.toIso8601String());
    }
  }

  Future<void> _ensureToday() async {
    final now = DateTime.now();
    if (_date != null &&
        _date!.year == now.year &&
        _date!.month == now.month &&
        _date!.day == now.day) {
      return;
    }
    _compute();
    _date = DateTime(now.year, now.month, now.day);
    _shown = false;
    await _save();
    notifyListeners();
  }

  Map<HeroPosition, _PosStats> _calc(List<SavedHand> list) {
    final map = <HeroPosition, _PosStats>{};
    for (final h in list) {
      final pos = parseHeroPosition(h.heroPosition);
      final prev = map[pos] ?? const _PosStats();
      final correct =
          h.expectedAction?.trim().toLowerCase() ==
          h.gtoAction?.trim().toLowerCase();
      map[pos] = _PosStats(
        hands: prev.hands + 1,
        correct: prev.correct + (correct ? 1 : 0),
        ev: prev.ev + (h.heroEv ?? 0),
        icm: prev.icm + (h.heroIcmEv ?? 0),
      );
    }
    final res = <HeroPosition, _PosStats>{};
    for (final e in map.entries) {
      res[e.key] = _PosStats(
        hands: e.value.hands,
        correct: e.value.correct,
        ev: e.value.hands > 0 ? e.value.ev / e.value.hands : 0,
        icm: e.value.hands > 0 ? e.value.icm / e.value.hands : 0,
      );
    }
    return res;
  }

  void _compute() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final start = DateTime(yesterday.year, yesterday.month, yesterday.day);
    final end = start.add(const Duration(days: 1));
    final yHands = [
      for (final h in hands.hands)
        if (!h.date.isBefore(start) && h.date.isBefore(end)) h,
    ];
    if (yHands.isEmpty) {
      _summary = '';
      _focus = null;
      return;
    }
    final prevStart = start.subtract(const Duration(days: 1));
    final prevEnd = start;
    final prevHands = [
      for (final h in hands.hands)
        if (!h.date.isBefore(prevStart) && h.date.isBefore(prevEnd)) h,
    ];
    final currMap = _calc(yHands);
    final prevMap = _calc(prevHands);
    HeroPosition? bestPos;
    double bestDiff = 0;
    HeroPosition? worstPos;
    double worstDiff = 0;
    for (final pos in currMap.keys) {
      final curr = currMap[pos]!;
      final prev = prevMap[pos];
      final delta = curr.accuracy - (prev?.accuracy ?? curr.accuracy);
      if (delta > bestDiff) {
        bestDiff = delta;
        bestPos = pos;
      }
      if (delta < worstDiff) {
        worstDiff = delta;
        worstPos = pos;
      }
    }
    _focus = worstPos;
    final parts = <String>[];
    if (bestDiff > 0 && bestPos != null) {
      parts.add('${bestPos.label} +${(bestDiff * 100).toStringAsFixed(1)}%');
    }
    if (worstDiff < 0 && worstPos != null) {
      parts.add('${worstPos.label} ${(worstDiff * 100).toStringAsFixed(1)}%');
    }
    _summary = parts.isEmpty ? '' : 'Сегодня: ${parts.join(', ')}';
  }
}
