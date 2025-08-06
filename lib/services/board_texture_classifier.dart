import '../models/v2/training_pack_spot.dart';

/// Simple board texture classifier used during auto-generation.
class BoardTextureClassifier {
  const BoardTextureClassifier();

  /// Returns a rough classification for [spot]'s board.
  String classify(TrainingPackSpot spot) {
    final board = spot.board;
    if (board.length >= 3) {
      final ranks = board.map((c) => c[0]).toList();
      final unique = ranks.toSet();
      if (unique.length < ranks.length) {
        return 'paired';
      }
    }
    return 'unpaired';
  }

  /// Annotates each spot with a `boardTexture` meta field.
  void classifyAll(Iterable<TrainingPackSpot> spots) {
    for (final s in spots) {
      s.meta['boardTexture'] = classify(s);
    }
  }
}

