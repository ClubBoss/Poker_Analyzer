import '../models/constraint_set.dart';
import '../models/spot_seed_format.dart';
import 'action_pattern_matcher.dart';
import 'dynamic_board_tagger_service.dart';

class ConstraintResolverEngine {
  final DynamicBoardTaggerService _tagger;
  final ActionPatternMatcher _actionMatcher;

  const ConstraintResolverEngine({
    DynamicBoardTaggerService? tagger,
    ActionPatternMatcher? actionMatcher,
  })  : _tagger = tagger ?? const DynamicBoardTaggerService(),
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
      final actualTags = _tagger.tag(candidate.board);
      if (!constraints.boardTags
          .every((tag) => actualTags.contains(tag))) {
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
