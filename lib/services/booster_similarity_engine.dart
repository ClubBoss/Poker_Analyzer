import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/spot_similarity_result.dart';
import '../helpers/hand_utils.dart';

/// Computes similarity between booster spots to detect duplicates.
class BoosterSimilarityEngine {
  BoosterSimilarityEngine();

  /// Returns pairs of spot ids with similarity above [threshold].
  List<SpotSimilarityResult> analyzeSpots(
    List<TrainingPackSpot> spots, {
    double threshold = 0.85,
  }) {
    final results = <SpotSimilarityResult>[];
    for (var i = 0; i < spots.length; i++) {
      for (var j = i + 1; j < spots.length; j++) {
        final sim = _similarity(spots[i], spots[j]);
        if (sim > threshold) {
          results.add(
            SpotSimilarityResult(
              idA: spots[i].id,
              idB: spots[j].id,
              similarity: sim,
            ),
          );
        }
      }
    }
    results.sort((a, b) => b.similarity.compareTo(a.similarity));
    return results;
  }

  /// Convenience wrapper to analyze all spots in [pack].
  List<SpotSimilarityResult> analyzePack(
    TrainingPackTemplateV2 pack, {
    double threshold = 0.85,
  }) => analyzeSpots(pack.spots, threshold: threshold);

  double _similarity(TrainingPackSpot a, TrainingPackSpot b) {
    final cardsA = _heroMask(a);
    final cardsB = _heroMask(b);
    final cardSim = (cardsA.isNotEmpty && cardsA == cardsB) ? 1.0 : 0.0;

    final posSim = a.hand.position == b.hand.position ? 1.0 : 0.0;

    final boardA = _normBoard(a.board.isNotEmpty ? a.board : a.hand.board);
    final boardB = _normBoard(b.board.isNotEmpty ? b.board : b.hand.board);
    final boardSim = (boardA.isNotEmpty && boardA == boardB) ? 1.0 : 0.0;

    final evA = a.heroEv ?? a.heroIcmEv;
    final evB = b.heroEv ?? b.heroIcmEv;
    double evSim = 0.5;
    if (evA != null && evB != null) {
      final diff = (evA - evB).abs();
      evSim = 1 - (diff.clamp(0, 1));
    }

    final lineA = _actionLine(a);
    final lineB = _actionLine(b);
    final actionSim = lineA.isNotEmpty && lineA == lineB ? 1.0 : 0.0;

    return cardSim * 0.3 +
        posSim * 0.2 +
        boardSim * 0.2 +
        evSim * 0.2 +
        actionSim * 0.1;
  }

  String _heroMask(TrainingPackSpot s) {
    final code = handCode(s.hand.heroCards);
    return code ?? '';
  }

  String _normBoard(List<String> board) =>
      board.map((c) => c.toUpperCase()).join(' ');

  String _actionLine(TrainingPackSpot s) {
    final actions = s.hand.actions.values.expand((e) => e).toList();
    if (actions.isEmpty) return '';
    return actions
        .map((a) => '${a.playerIndex}:${a.action}${a.amount ?? ''}')
        .join('|');
  }
}
