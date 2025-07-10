import 'package:flutter/foundation.dart';
import '../models/v2/hero_position.dart';
import 'pack_generator_service.dart';
import 'saved_hand_manager_service.dart';
import 'player_progress_service.dart';
import '../models/v2/training_pack_template.dart';

class WeakSpotRecommendation {
  final HeroPosition position;
  final double accuracy;
  final int hands;
  const WeakSpotRecommendation({
    required this.position,
    required this.accuracy,
    required this.hands,
  });
}

class WeakSpotRecommendationService extends ChangeNotifier {
  final SavedHandManagerService hands;
  final PlayerProgressService progress;
  WeakSpotRecommendation? _rec;
  WeakSpotRecommendation? get recommendation => _rec;
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
    } else {
      final entry = progress.progress.entries.reduce(
        (a, b) => a.value.accuracy <= b.value.accuracy ? a : b,
      );
      _rec = WeakSpotRecommendation(
        position: entry.key,
        accuracy: entry.value.accuracy,
        hands: entry.value.hands,
      );
    }
    notifyListeners();
  }

  Future<TrainingPackTemplate?> buildPack() async {
    final pos = _rec?.position;
    if (pos == null) return null;
    final acc = _rec!.accuracy;
    final stack = (15 + ((0.5 - acc) * 10)).round().clamp(5, 25);
    final pct = (25 + ((0.5 - acc) * 50)).round().clamp(5, 100);
    final heroPos = pos;
    return PackGeneratorService.generatePushFoldPack(
      id: 'weak_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Focus ${heroPos.label}',
      heroBbStack: stack,
      playerStacksBb: [stack, stack],
      heroPos: heroPos,
      heroRange: PackGeneratorService.topNHands(pct).toList(),
    );
  }
}
