import '../models/card_model.dart';
import '../utils/board_analyzer_utils.dart';

/// Maps raw boards into abstracted cluster labels used for filtering.
class BoardClusterLibrary {
  const BoardClusterLibrary._();

  /// Returns a set of cluster names describing [board].
  ///
  /// Cluster names are derived from dynamic board tags with a few
  /// additional composites for convenience (e.g. `static` for dry boards,
  /// `trap` for paired/monotone boards, `broadway-heavy` for broadway
  /// boards).
  static Set<String> getClusters(List<CardModel> board) {
    final tags =
        BoardAnalyzerUtils.tags(board).map((t) => t.toLowerCase()).toSet();
    final clusters = <String>{...tags};

    if (tags.contains('dry')) clusters.add('static');
    if (tags.contains('broadway')) clusters.add('broadway-heavy');
    if (tags.contains('paired') || tags.contains('monotone'))
      clusters.add('trap');
    if (tags.contains('wet')) clusters.add('highinteraction');

    return clusters;
  }
}
