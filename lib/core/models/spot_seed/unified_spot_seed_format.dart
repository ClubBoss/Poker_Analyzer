/// Represents a normalized poker spot used to generate training content.
class UnifiedSpotSeedFormat {
  /// Unique identifier for this seed.
  final String id;

  /// Type of training (preflop, postflop, etc.).
  final String trainingType;

  /// Primary goal for this training spot.
  final String goal;

  /// High level theme or category for filtering.
  final String theme;

  /// Human readable description of the scenario.
  final String description;

  /// Player position at the table (e.g. UTG, BTN).
  final String position;

  /// Action hero is facing (e.g. open, 3bet, shove).
  final String actionFacing;

  /// Board street for this scenario: preflop, flop, turn, river.
  final String boardStreet;

  /// Tags used for clustering and search.
  final List<String> tags;

  /// Difficulty level of the spot.
  final String level;

  /// Estimated number of spots generated from this seed.
  final int spotCount;

  /// Additional metadata used by generators.
  final Map<String, dynamic> meta;

  UnifiedSpotSeedFormat({
    required this.id,
    required this.trainingType,
    required this.goal,
    required this.theme,
    required this.description,
    required this.position,
    required this.actionFacing,
    required this.boardStreet,
    List<String>? tags,
    required this.level,
    required this.spotCount,
    Map<String, dynamic>? meta,
  })  : tags = tags ?? const <String>[],
        meta = meta ?? const <String, dynamic>{};
}

