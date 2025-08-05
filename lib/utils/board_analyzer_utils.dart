import '../models/card_model.dart';
import '../services/dynamic_board_tagger_service.dart';

/// Utility helpers for evaluating board textures.
class BoardAnalyzerUtils {
  BoardAnalyzerUtils._();

  static final DynamicBoardTaggerService _tagger =
      const DynamicBoardTaggerService();

  /// Returns a set of tags describing the given [board].
  static Set<String> tags(List<CardModel> board) => _tagger.tag(board);
}
