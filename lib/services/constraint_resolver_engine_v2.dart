import '../models/constraint_set.dart';
import '../models/spot_seed_format.dart';
import 'board_texture_filter_service.dart';
import 'action_pattern_matcher.dart';

class ConstraintResolverEngine {
  final BoardTextureFilterService _textureFilter;
  final ActionPatternMatcher _actionMatcher;

  const ConstraintResolverEngine({
    BoardTextureFilterService? textureFilter,
    ActionPatternMatcher? actionMatcher,
  })  : _textureFilter = textureFilter ?? const BoardTextureFilterService(),
        _actionMatcher = actionMatcher ?? const ActionPatternMatcher();

  bool isValid(SpotSeedFormat candidate, ConstraintSet constraints) {
    if (constraints.positions.isNotEmpty &&
        !constraints.positions
            .map((e) => e.toLowerCase())
            .contains(candidate.position.toLowerCase())) {
      return false;
    }

    if (constraints.handGroup.isNotEmpty &&
        !candidate.handGroup.any((h) =>
            constraints.handGroup.map((e) => e.toLowerCase()).contains(h.toLowerCase()))) {
      return false;
    }

    if (constraints.boardTags.isNotEmpty) {
      final board = candidate.board.map((c) => c.toString()).toList();
      if (!_textureFilter.filter(board, constraints.boardTags)) {
        return false;
      }
    }

    if (constraints.villainActions.isNotEmpty &&
        !_actionMatcher.matches(
            candidate.villainActions, constraints.villainActions)) {
      return false;
    }

    if (constraints.targetStreet != null &&
        constraints.targetStreet!.isNotEmpty &&
        candidate.currentStreet.toLowerCase() !=
            constraints.targetStreet!.toLowerCase()) {
      return false;
    }

    return true;
  }
}
