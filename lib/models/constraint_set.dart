import '../services/inline_theory_linker.dart';
import 'line_pattern.dart';

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

  /// Optional list of board generation constraints to expand into concrete
  /// boards for this variation.
  final List<Map<String, dynamic>> boardConstraints;

  /// Optional action line pattern that should be applied to each generated
  /// variation.
  final LinePattern? linePattern;

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
    this.boardConstraints = const [],
    this.linePattern,
    this.overrides = const {},
    this.tags = const [],
    this.tagMergeMode = MergeMode.add,
    this.metadata = const {},
    this.metaMergeMode = MergeMode.add,
    this.theoryLink,
  });

  factory ConstraintSet.fromJson(Map<String, dynamic> json) {
    final overrides = <String, List<dynamic>>{};
    if (json['overrides'] is Map) {
      (json['overrides'] as Map).forEach((key, value) {
        overrides[key.toString()] = [
          for (final v in (value as List? ?? [])) v,
        ];
      });
    }
    return ConstraintSet(
      boardTags: [
        for (final t in (json['boardTags'] as List? ?? [])) t.toString(),
      ],
      positions: [
        for (final p in (json['positions'] as List? ?? [])) p.toString(),
      ],
      handGroup: [
        for (final g in (json['handGroup'] as List? ?? [])) g.toString(),
      ],
      villainActions: [
        for (final a in (json['villainActions'] as List? ?? [])) a.toString(),
      ],
      targetStreet: json['targetStreet']?.toString(),
      boardConstraints: [
        if (json['boardConstraints'] is List)
          for (final c in (json['boardConstraints'] as List))
            Map<String, dynamic>.from(c as Map),
      ],
      linePattern: json['linePattern'] is Map
          ? LinePattern.fromJson(Map<String, dynamic>.from(json['linePattern']))
          : null,
      overrides: overrides,
      tags: [
        for (final t in (json['tags'] as List? ?? [])) t.toString(),
      ],
      tagMergeMode: json['tagMergeMode'] == 'override'
          ? MergeMode.override
          : MergeMode.add,
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'])
          : const {},
      metaMergeMode: json['metaMergeMode'] == 'override'
          ? MergeMode.override
          : MergeMode.add,
    );
  }

  Map<String, dynamic> toJson() => {
        if (boardTags.isNotEmpty) 'boardTags': boardTags,
        if (positions.isNotEmpty) 'positions': positions,
        if (handGroup.isNotEmpty) 'handGroup': handGroup,
        if (villainActions.isNotEmpty) 'villainActions': villainActions,
        if (targetStreet != null) 'targetStreet': targetStreet,
        if (boardConstraints.isNotEmpty) 'boardConstraints': boardConstraints,
        if (linePattern != null) 'linePattern': linePattern!.toJson(),
        if (overrides.isNotEmpty) 'overrides': overrides,
        if (tags.isNotEmpty) 'tags': tags,
        if (tagMergeMode == MergeMode.override) 'tagMergeMode': 'override',
        if (metadata.isNotEmpty) 'metadata': metadata,
        if (metaMergeMode == MergeMode.override) 'metaMergeMode': 'override',
      };
}

/// Strategy for merging list/map data when applying a [ConstraintSet].
enum MergeMode { add, override }
