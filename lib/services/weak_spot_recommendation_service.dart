import 'package:flutter/foundation.dart';
import '../models/v2/hero_position.dart';
import 'evaluation_executor_service.dart';
import 'pack_generator_service.dart';
import 'saved_hand_manager_service.dart';
import '../models/v2/training_pack_template.dart';

class WeakSpotRecommendation {
  final String position;
  final int mistakes;
  WeakSpotRecommendation({required this.position, required this.mistakes});
}

class WeakSpotRecommendationService extends ChangeNotifier {
  final SavedHandManagerService hands;
  final EvaluationExecutorService eval;
  WeakSpotRecommendation? _rec;
  WeakSpotRecommendation? get recommendation => _rec;
  WeakSpotRecommendationService({required this.hands, required this.eval}) {
    _update();
    hands.addListener(_update);
  }

  void _update() {
    final summary = eval.summarizeHands(hands.hands);
    if (summary.positionMistakeFrequencies.isEmpty) {
      _rec = null;
    } else {
      final entry = summary.positionMistakeFrequencies.entries
          .reduce((a, b) => a.value >= b.value ? a : b);
      _rec = WeakSpotRecommendation(position: entry.key, mistakes: entry.value);
    }
    notifyListeners();
  }

  Future<TrainingPackTemplate?> buildPack() async {
    final pos = _rec?.position;
    if (pos == null) return null;
    final heroPos = parseHeroPosition(pos);
    return PackGeneratorService.generatePushFoldPack(
      id: 'weak_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Focus $pos',
      heroBbStack: 15,
      playerStacksBb: const [15, 15],
      heroPos: heroPos,
      heroRange: PackGeneratorService.topNHands(25).toList(),
    );
  }
}
