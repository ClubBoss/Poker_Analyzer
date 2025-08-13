import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'progress_forecast_service.dart';
import '../models/v2/training_pack_template.dart';
import '../models/v2/hero_position.dart';
import '../helpers/poker_position_helper.dart';
import '../helpers/hand_utils.dart';
import 'template_storage_service.dart';
import 'training_pack_stats_service.dart';
import 'mistake_review_pack_service.dart';
import 'saved_hand_manager_service.dart';
import 'hand_analysis_history_service.dart';
import 'xp_tracker_service.dart';
import 'pack_generator_service.dart';
import 'player_style_service.dart';
import 'player_style_forecast_service.dart';

class AdaptiveTrainingService extends ChangeNotifier {
  final TemplateStorageService templates;
  final MistakeReviewPackService mistakes;
  final SavedHandManagerService hands;
  final HandAnalysisHistoryService history;
  final XPTrackerService xp;
  final ProgressForecastService forecast;
  final PlayerStyleService style;
  final PlayerStyleForecastService styleForecast;
  AdaptiveTrainingService({
    required this.templates,
    required this.mistakes,
    required this.hands,
    required this.history,
    required this.xp,
    required this.forecast,
    required this.style,
    required this.styleForecast,
  }) {
    refresh();
    templates.addListener(refresh);
    mistakes.addListener(refresh);
    hands.addListener(refresh);
    history.addListener(refresh);
    xp.addListener(refresh);
    forecast.addListener(refresh);
    style.addListener(refresh);
    styleForecast.addListener(refresh);
  }

  List<TrainingPackTemplate> _recommended = [];
  Map<String, TrainingPackStat?> _stats = {};
  final ValueNotifier<List<TrainingPackTemplate>> recommendedNotifier =
      ValueNotifier(<TrainingPackTemplate>[]);

  List<TrainingPackTemplate> get recommended => List.unmodifiable(_recommended);
  TrainingPackStat? statFor(String id) => _stats[id];

  Future<void> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    var level = xp.level;
    final f = forecast.forecast;
    if (f.accuracy < 0.6) {
      level -= 2;
    } else if (f.accuracy < 0.75) level -= 1;
    if (f.ev < 0) level -= 1;
    if (f.icm < 0) level -= 1;
    if (f.accuracy > 0.9 && f.ev > 0 && f.icm > 0) level += 1;
    level = level.clamp(1, 40);
    final posCounts = <HeroPosition, int>{};
    final posLoss = <HeroPosition, double>{};
    final posIcmLoss = <HeroPosition, double>{};
    for (final h in hands.hands.reversed.take(50)) {
      final exp = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      if (exp != null &&
          gto != null &&
          exp.isNotEmpty &&
          gto.isNotEmpty &&
          exp != gto) {
        final pos = parseHeroPosition(h.heroPosition);
        posCounts[pos] = (posCounts[pos] ?? 0) + 1;
        final ev =
            h.evLoss ?? (h.heroEv != null && h.heroEv! < 0 ? -h.heroEv! : 0);
        if (ev > 0) posLoss[pos] = (posLoss[pos] ?? 0) + ev;
        final icm = h.heroIcmEv;
        if (icm != null && icm < 0)
          posIcmLoss[pos] = (posIcmLoss[pos] ?? 0) + icm.abs();
      }
    }
    for (final r in history.records.take(50)) {
      final order = getPositionList(r.playerCount);
      if (r.heroIndex < order.length) {
        final pos = parseHeroPosition(order[r.heroIndex]);
        posCounts[pos] = (posCounts[pos] ?? 0) + 1;
        if (r.ev < 0) posLoss[pos] = (posLoss[pos] ?? 0) + r.ev.abs();
        if (r.icm < 0) posIcmLoss[pos] = (posIcmLoss[pos] ?? 0) + r.icm.abs();
      }
    }
    final entries = <MapEntry<TrainingPackTemplate, double>>[];
    final stats = <String, TrainingPackStat?>{};
    for (final t in templates.templates) {
      if (!t.isBuiltIn) continue;
      if (prefs.getBool('completed_tpl_${t.id}') ?? false) continue;
      final stat = await TrainingPackStatsService.getStats(t.id);
      stats[t.id] = stat;
      final miss = mistakes.mistakeCount(t.id);
      final posMiss = posCounts[t.heroPos] ?? 0;
      final loss = posLoss[t.heroPos] ?? 0;
      final icmLoss = posIcmLoss[t.heroPos] ?? 0;
      var score = 1 - (stat?.accuracy ?? 0);
      score += 1 - (stat?.postEvPct ?? 0) / 100;
      score += 1 - (stat?.postIcmPct ?? 0) / 100;
      final dEv = (stat?.postEvPct ?? 0) - (stat?.preEvPct ?? 0);
      final dIcm = (stat?.postIcmPct ?? 0) - (stat?.preIcmPct ?? 0);
      score -= dEv * .05;
      score -= dIcm * .05;
      if (miss > 0) score += 2 + miss * .5;
      if (posMiss > 0) score += 1 + posMiss * .3;
      if (loss > 0) score += loss * .1;
      if (icmLoss > 0) score += icmLoss * .1;
      final diff = (t.difficultyLevel - level).abs();
      score += diff * 0.3;
      entries.add(MapEntry(t, score));
    }
    entries.sort((a, b) => b.value.compareTo(a.value));
    _recommended = [for (final e in entries.take(5)) e.key];
    recommendedNotifier.value = List<TrainingPackTemplate>.from(_recommended);
    _stats = stats;
    notifyListeners();
  }

  Future<TrainingPackTemplate> buildAdaptivePack() async {
    final posCounts = <HeroPosition, int>{};
    final handLoss = <String, double>{};
    for (final h in hands.hands.reversed.take(50)) {
      final exp = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      if (exp != null &&
          gto != null &&
          exp.isNotEmpty &&
          gto.isNotEmpty &&
          exp != gto) {
        final pos = parseHeroPosition(h.heroPosition);
        posCounts[pos] = (posCounts[pos] ?? 0) + 1;
        if (h.playerCards.length > h.heroIndex &&
            h.playerCards[h.heroIndex].length >= 2) {
          final c1 = h.playerCards[h.heroIndex][0];
          final c2 = h.playerCards[h.heroIndex][1];
          final code = handCode('${c1.rank}${c1.suit} ${c2.rank}${c2.suit}');
          final loss =
              h.evLoss ?? (h.heroEv != null && h.heroEv! < 0 ? -h.heroEv! : 0);
          if (code != null && loss > 0) {
            handLoss[code] = (handLoss[code] ?? 0) + loss;
          }
        }
      }
    }
    for (final r in history.records.take(50)) {
      final order = getPositionList(r.playerCount);
      if (r.heroIndex < order.length) {
        final pos = parseHeroPosition(order[r.heroIndex]);
        if (r.ev < 0) posCounts[pos] = (posCounts[pos] ?? 0) + 1;
        final code = handCode('${r.card1} ${r.card2}');
        if (code != null && r.ev < 0) {
          handLoss[code] = (handLoss[code] ?? 0) + r.ev.abs();
        }
      }
    }
    var best = HeroPosition.sb;
    var max = 0;
    posCounts.forEach((p, c) {
      if (c > max) {
        max = c;
        best = p;
      }
    });
    var stack = (10 + xp.level).clamp(5, 25);
    switch (styleForecast.forecast) {
      case PlayerStyle.aggressive:
        stack -= 2;
        break;
      case PlayerStyle.passive:
        stack += 2;
        break;
      case PlayerStyle.neutral:
        break;
    }
    stack = stack.clamp(5, 25);
    final rangeEntries = handLoss.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final range = <String>[];
    for (final e in rangeEntries.take(20)) {
      range.add(e.key);
    }
    int pct;
    switch (styleForecast.forecast) {
      case PlayerStyle.aggressive:
        pct = 15;
        break;
      case PlayerStyle.passive:
        pct = 35;
        break;
      case PlayerStyle.neutral:
        pct = 25;
        break;
    }
    if (range.length < 20) {
      range.addAll(
        PackGeneratorService.topNHands(pct)
            .where((h) => !range.contains(h))
            .take(20 - range.length),
      );
    }
    return PackGeneratorService.generatePushFoldPack(
      id: 'adaptive_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Adaptive ${best.label}',
      heroBbStack: stack,
      playerStacksBb: [stack, stack],
      heroPos: best,
      heroRange: range,
    );
  }

  Future<TrainingPackTemplate?> nextRecommendedPack() async {
    await refresh();
    final prefs = await SharedPreferences.getInstance();
    for (final t in _recommended) {
      final idx = prefs.getInt('tpl_prog_${t.id}') ?? 0;
      if (idx < t.spots.length) return t;
    }
    return null;
  }
}
