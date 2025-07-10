import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/v2/training_pack_template.dart';
import '../models/v2/hero_position.dart';
import '../helpers/poker_position_helper.dart';
import 'template_storage_service.dart';
import 'training_pack_stats_service.dart';
import 'mistake_review_pack_service.dart';
import 'saved_hand_manager_service.dart';
import 'hand_analysis_history_service.dart';
import 'xp_tracker_service.dart';
import 'pack_generator_service.dart';

class AdaptiveTrainingService extends ChangeNotifier {
  final TemplateStorageService templates;
  final MistakeReviewPackService mistakes;
  final SavedHandManagerService hands;
  final HandAnalysisHistoryService history;
  final XPTrackerService xp;
  AdaptiveTrainingService({
    required this.templates,
    required this.mistakes,
    required this.hands,
    required this.history,
    required this.xp,
  }) {
    refresh();
    templates.addListener(refresh);
    mistakes.addListener(refresh);
    hands.addListener(refresh);
    history.addListener(refresh);
    xp.addListener(refresh);
  }

  List<TrainingPackTemplate> _recommended = [];
  Map<String, TrainingPackStat?> _stats = {};
  final ValueNotifier<List<TrainingPackTemplate>> recommendedNotifier =
      ValueNotifier(<TrainingPackTemplate>[]);

  List<TrainingPackTemplate> get recommended => List.unmodifiable(_recommended);
  TrainingPackStat? statFor(String id) => _stats[id];

  Future<void> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final level = xp.level;
    final posCounts = <HeroPosition, int>{};
    final posLoss = <HeroPosition, double>{};
    for (final h in hands.hands.reversed.take(50)) {
      final exp = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      if (exp != null && gto != null && exp.isNotEmpty && gto.isNotEmpty && exp != gto) {
        final pos = parseHeroPosition(h.heroPosition);
        posCounts[pos] = (posCounts[pos] ?? 0) + 1;
        posLoss[pos] = (posLoss[pos] ?? 0) + (h.evLoss ?? 0);
      }
    }
    for (final r in history.records.take(50)) {
      final order = getPositionList(r.playerCount);
      if (r.heroIndex < order.length) {
        final pos = parseHeroPosition(order[r.heroIndex]);
        posCounts[pos] = (posCounts[pos] ?? 0) + 1;
        if (r.ev < 0) posLoss[pos] = (posLoss[pos] ?? 0) + r.ev.abs();
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
    for (final h in hands.hands.reversed.take(50)) {
      final exp = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      if (exp != null && gto != null && exp.isNotEmpty && gto.isNotEmpty && exp != gto) {
        final pos = parseHeroPosition(h.heroPosition);
        posCounts[pos] = (posCounts[pos] ?? 0) + 1;
      }
    }
    for (final r in history.records.take(50)) {
      final order = getPositionList(r.playerCount);
      if (r.heroIndex < order.length) {
        final pos = parseHeroPosition(order[r.heroIndex]);
        if (r.ev < 0) posCounts[pos] = (posCounts[pos] ?? 0) + 1;
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
    final stack = (10 + xp.level).clamp(5, 25);
    return PackGeneratorService.generatePushFoldPack(
      id: 'adaptive_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Adaptive ${best.label}',
      heroBbStack: stack,
      playerStacksBb: [stack, stack],
      heroPos: best,
      heroRange: PackGeneratorService.topNHands(20).toList(),
    );
  }
}
