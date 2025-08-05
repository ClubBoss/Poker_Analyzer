import "../models/card_model.dart";
import "board_cluster_library.dart";

class BoardClusterConstraintEngine {
  const BoardClusterConstraintEngine._();

  static bool matches({
    required List<CardModel> board,
    List<String>? requiredClusters,
    List<String>? excludedClusters,
  }) {
    final req = [
      for (final c in requiredClusters ?? const []) c.toLowerCase(),
    ];
    final excl = [
      for (final c in excludedClusters ?? const []) c.toLowerCase(),
    ];
    if (req.isEmpty && excl.isEmpty) return true;
    final clusters = BoardClusterLibrary.getClusters(board)
        .map((c) => c.toLowerCase())
        .toSet();
    for (final r in req) {
      if (!clusters.contains(r)) return false;
    }
    for (final e in excl) {
      if (clusters.contains(e)) return false;
    }
    return true;
  }
}
