import 'package:flutter/foundation.dart';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'package:collection/collection.dart';

import '../core/training/engine/training_type_engine.dart';
import '../models/v2/hero_position.dart';
import '../models/v2/training_pack_template.dart';
import 'pack_generator_service.dart';
import 'saved_hand_manager_service.dart';
import 'player_progress_service.dart';
import 'pack_library_loader_service.dart';
import 'training_pack_stats_service.dart';
import 'training_stats_service.dart';
import 'training_history_service_v2.dart';

class WeakSpotRecommendation {
  final HeroPosition position;
  final double accuracy;
  final double ev;
  final double icm;
  final int hands;
  const WeakSpotRecommendation({
    required this.position,
    required this.accuracy,
    required this.ev,
    required this.icm,
    required this.hands,
  });

  double get score {
    var s = 1 - accuracy;
    if (ev < 0) s += -ev * .1;
    if (icm < 0) s += -icm * .1;
    return s;
  }
}

class WeakSpotRecommendationService extends ChangeNotifier {
  final SavedHandManagerService hands;
  final PlayerProgressService progress;
  WeakSpotRecommendation? _rec;
  List<WeakSpotRecommendation> _list = [];
  WeakSpotRecommendation? get recommendation => _rec;
  List<WeakSpotRecommendation> get recommendations => List.unmodifiable(_list);
  WeakSpotRecommendationService({
    required this.hands,
    required this.progress,
  }) {
    _update();
    hands.addListener(_update);
    progress.addListener(_update);
  }

  void _update() {
    if (progress.progress.isEmpty) {
      _rec = null;
      _list = [];
    } else {
      final list = <WeakSpotRecommendation>[];
      for (final e in progress.progress.entries) {
        if (e.value.hands < 5) continue;
        list.add(
          WeakSpotRecommendation(
            position: e.key,
            accuracy: e.value.accuracy,
            ev: e.value.ev,
            icm: e.value.icm,
            hands: e.value.hands,
          ),
        );
      }
      list.sort((a, b) => b.score.compareTo(a.score));
      _list = list.take(3).toList();
      _rec = _list.isEmpty ? null : _list.first;
    }
    notifyListeners();
  }

  Future<TrainingPackTemplate?> buildPack([HeroPosition? pos]) async {
    final rec = pos == null
        ? _rec
        : _list.firstWhere(
            (e) => e.position == pos,
            orElse: () => _rec ??
                WeakSpotRecommendation(
                    position: pos,
                    accuracy: 0.5,
                    ev: 0,
                    icm: 0,
                    hands: 0,
                  ),
          );
    if (rec == null) return null;
    final acc = rec.accuracy;
    var stack = (15 + ((0.5 - acc) * 10)).round();
    stack += rec.ev < 0 ? 1 : 0;
    stack += rec.icm < 0 ? 1 : 0;
    final bb = stack.clamp(5, 25);
    final pct = (25 + ((0.5 - acc) * 50)).round().clamp(5, 100);
    final heroPos = rec.position;
    return PackGeneratorService.generatePushFoldPack(
      id: 'weak_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Focus ${heroPos.label}',
      heroBbStack: bb,
      playerStacksBb: [bb, bb],
      heroPos: heroPos,
      heroRange: PackGeneratorService.topNHands(pct).toList(),
    );
  }

  Future<String?> getRecommendedCategory() async {
    final stats = await TrainingPackStatsService.getCategoryStats();
    if (stats.isEmpty) return null;
    final list = stats.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return list.first.key;
  }

  Future<String?> detectWeakTrainingType({
    int minLaunches = 10,
    Duration recent = const Duration(days: 3),
  }) async {
    final prefs = await PreferencesService.getInstance();
    final now = DateTime.now();
    final cacheTime = DateTime.tryParse(
        prefs.getString('weak_training_type_time') ?? '');
    final cacheVal = prefs.getString('weak_training_type_val');
    if (cacheVal != null &&
        cacheTime != null &&
        now.difference(cacheTime) < const Duration(days: 1)) {
      return cacheVal.isEmpty ? null : cacheVal;
    }

    final statsService = TrainingStatsService.instance;
    if (statsService == null) return null;

    await PackLibraryLoaderService.instance.loadLibrary();
    final library = PackLibraryLoaderService.instance.library;

    final launches = <TrainingType, int>{};
    final hands = <TrainingType, int>{};
    final mistakes = <TrainingType, int>{};

    for (final pack in library) {
      final s = await statsService.getStatsForPack(pack.id);
      if (s.launches == 0) continue;
      launches.update(pack.trainingType, (v) => v + s.launches,
          ifAbsent: () => s.launches);
      hands.update(pack.trainingType, (v) => v + s.totalTrained,
          ifAbsent: () => s.totalTrained);
      mistakes.update(pack.trainingType, (v) => v + s.mistakes,
          ifAbsent: () => s.mistakes);
    }

    final accuracy = <TrainingType, double>{};
    for (final type in hands.keys) {
      final total = hands[type] ?? 0;
      final miss = mistakes[type] ?? 0;
      if (total > 0) {
        accuracy[type] = (total - miss) / total;
      }
    }

    if (accuracy.isEmpty) {
      await prefs.setString('weak_training_type_time', now.toIso8601String());
      await prefs.setString('weak_training_type_val', '');
      return null;
    }

    final history = await TrainingHistoryServiceV2.getHistory(limit: 50);
    final cutoff = now.subtract(recent);
    final recentTypes = <TrainingType>{};
    for (final entry in history) {
      if (entry.timestamp.isBefore(cutoff)) break;
      final tpl =
          library.firstWhereOrNull((t) => t.id == entry.packId);
      if (tpl != null) recentTypes.add(tpl.trainingType);
    }

    TrainingType? weakest;
    double weakestAcc = 2.0;
    for (final type in accuracy.keys) {
      final acc = accuracy[type]!;
      final count = launches[type] ?? 0;
      if (count < minLaunches) continue;
      if (recentTypes.contains(type)) continue;
      if (acc < weakestAcc) {
        weakestAcc = acc;
        weakest = type;
      }
    }

    final result = (weakest != null && weakestAcc < 0.9)
        ? weakest.name
        : null;

    await prefs.setString('weak_training_type_time', now.toIso8601String());
    await prefs.setString('weak_training_type_val', result ?? '');
    return result;
  }
}
