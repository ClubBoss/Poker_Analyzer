import 'package:flutter/foundation.dart';
import '../models/v2/hero_position.dart';
import 'pack_generator_service.dart';
import 'saved_hand_manager_service.dart';
import 'player_progress_service.dart';
import '../models/v2/training_pack_template.dart';
import 'training_pack_stats_service.dart';

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
}
