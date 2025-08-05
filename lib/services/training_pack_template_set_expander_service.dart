import '../models/training_pack_template_set.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/card_model.dart';
import 'training_pack_template_expander_service.dart';
import 'board_cluster_constraint_engine.dart';

/// Expands a [TrainingPackTemplateSet] into concrete [TrainingPackSpot]s.
///
/// This service delegates board and variation resolution to
/// [TrainingPackTemplateExpanderService] and then applies optional board
/// cluster filters via [BoardClusterConstraintEngine].
class TrainingPackTemplateSetExpanderService {
  final TrainingPackTemplateExpanderService _expander;

  TrainingPackTemplateSetExpanderService({
    TrainingPackTemplateExpanderService? expander,
  }) : _expander = expander ?? TrainingPackTemplateExpanderService();

  /// Generates all spots described by [set].
  ///
  /// The underlying [TrainingPackTemplateExpanderService] is used to resolve
  /// variations and board generations. The resulting spots are then filtered
  /// against [TrainingPackTemplateSet.requiredBoardClusters] and
  /// [TrainingPackTemplateSet.excludedBoardClusters].
  List<TrainingPackSpot> expand(TrainingPackTemplateSet set) {
    final spots = _expander.expand(set);
    if (set.requiredBoardClusters.isEmpty &&
        set.excludedBoardClusters.isEmpty) {
      return spots;
    }
    return [
      for (final s in spots)
        if (BoardClusterConstraintEngine.matches(
          board: [
            for (final c in s.board)
              CardModel(rank: c[0], suit: c.length > 1 ? c[1] : ''),
          ],
          requiredClusters: set.requiredBoardClusters,
          excludedClusters: set.excludedBoardClusters,
        ))
          s,
    ];
  }
}
