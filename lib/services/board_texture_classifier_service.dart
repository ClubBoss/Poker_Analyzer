import '../models/v2/training_pack_spot.dart';
import '../models/card_model.dart';
import 'board_texture_classifier.dart';

/// Service that classifies board textures for [TrainingPackSpot]s.
class BoardTextureClassifierService {
  BoardTextureClassifierService({BoardTextureClassifier? classifier})
    : _classifier = classifier ?? const BoardTextureClassifier();

  final BoardTextureClassifier _classifier;

  /// Returns a map from spot id to list of texture tags.
  ///
  /// Each spot's `board` is analysed and a subset of texture tags is
  /// produced. Tags include:
  /// `low`, `aceHigh`, `paired`, `monotone`, `rainbow`, `twoTone`,
  /// `wet`, and `connected`.
  ///
  /// The resulting tags are also cached to `spot.meta['boardTextureTags']`.
  Map<String, List<String>> classify(List<TrainingPackSpot> spots) {
    final result = <String, List<String>>{};
    for (final spot in spots) {
      final cards = <CardModel>[
        for (final c in spot.board)
          if (c.length >= 2) CardModel(rank: c[0], suit: c[1]),
      ];
      final tags = _classifier.classifyCards(cards);
      final filtered = <String>{};
      if (tags.contains('low')) filtered.add('low');
      if (tags.contains('aceHigh')) filtered.add('aceHigh');
      if (tags.contains('paired')) filtered.add('paired');
      if (tags.contains('monotone')) filtered.add('monotone');
      if (tags.contains('rainbow')) filtered.add('rainbow');
      if (tags.contains('wet')) filtered.add('wet');
      if (tags.contains('connected')) filtered.add('connected');

      // Custom detection for twoTone: exactly two suits present.
      final suitCount = cards.map((c) => c.suit).toSet().length;
      if (suitCount == 2) filtered.add('twoTone');

      final tagList = filtered.toList();
      result[spot.id] = tagList;
      spot.meta['boardTextureTags'] = tagList;
    }
    return result;
  }
}
