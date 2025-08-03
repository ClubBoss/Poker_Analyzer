class ConstraintSet {
  final List<String> boardTags;
  final List<String> positions;
  final List<String> handGroup;
  final List<String> villainActions;
  final String? targetStreet;

  const ConstraintSet({
    this.boardTags = const [],
    this.positions = const [],
    this.handGroup = const [],
    this.villainActions = const [],
    this.targetStreet,
  });
}
