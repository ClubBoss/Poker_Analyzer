import '../services/inline_theory_linker.dart';

/// Describes a set of constraints and mutation rules that can be applied to a
/// base [TrainingPackSpot] to produce variations.
///
/// Existing fields such as [boardTags] and [villainActions] are used by other
/// parts of the system for filtering purposes.  The additional fields introduced
/// here allow the resolver engine to modify tags and inline metadata when
/// generating spots from templates.
class ConstraintSet {
  final List<String> boardTags;
  final List<String> positions;
  final List<String> handGroup;
  final List<String> villainActions;
  final String? targetStreet;

  /// Property overrides where each key maps to a list of possible values. The
  /// resolver engine will expand the cartesian product of these lists.
  final Map<String, List<dynamic>> overrides;

  /// Tags to inject into the resulting spot.  Behaviour is controlled by
  /// [tagMergeMode].
  final List<String> tags;

  /// Determines how [tags] are applied: [MergeMode.add] merges them with the
  /// base tags, while [MergeMode.override] replaces the base tags entirely.
  final MergeMode tagMergeMode;

  /// Arbitrary metadata to merge with or override the base spot's [meta].
  final Map<String, dynamic> metadata;

  /// Controls how [metadata] is applied. [MergeMode.add] merges the maps while
  /// [MergeMode.override] replaces the base metadata.
  final MergeMode metaMergeMode;

  /// Optional theory link override.
  final InlineTheoryLink? theoryLink;

  const ConstraintSet({
    this.boardTags = const [],
    this.positions = const [],
    this.handGroup = const [],
    this.villainActions = const [],
    this.targetStreet,
    this.overrides = const {},
    this.tags = const [],
    this.tagMergeMode = MergeMode.add,
    this.metadata = const {},
    this.metaMergeMode = MergeMode.add,
    this.theoryLink,
  });
}

/// Strategy for merging list/map data when applying a [ConstraintSet].
enum MergeMode { add, override }
