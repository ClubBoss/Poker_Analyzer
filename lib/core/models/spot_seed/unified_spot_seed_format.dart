/// Unified Spot Seed Format (USF).
///
/// Represents a canonical description of a poker training spot.
class SpotSeed {
  /// Unique identifier for this seed.
  final String id;

  /// Game type identifier (e.g. `cash`, `tournament`).
  final String gameType;

  /// Size of the big blind in chips.
  final double bb;

  /// Effective stack in big blinds.
  final double stackBB;

  /// Hero and optional villain positions.
  final SpotPositions positions;

  /// Ranges for hero and villain when available.
  final SpotRanges ranges;

  /// Board cards for each street.
  final SpotBoard board;

  /// Current pot size in big blinds.
  final double pot;

  /// ICM data for tournament contexts.
  final SpotIcm? icm;

  /// Normalized, lowercase tags.
  final List<String> tags;

  /// Optional difficulty level.
  final String? difficulty;

  /// Optional audience identifier.
  final String? audience;

  /// Additional metadata for generators.
  final Map<String, dynamic> meta;

  SpotSeed({
    required this.id,
    required this.gameType,
    required this.bb,
    required this.stackBB,
    required this.positions,
    required this.ranges,
    required this.board,
    required this.pot,
    this.icm,
    List<String>? tags,
    this.difficulty,
    this.audience,
    Map<String, dynamic>? meta,
  })  : tags = tags ?? const <String>[],
        meta = meta ?? const <String, dynamic>{};
}

/// Holds positional information.
class SpotPositions {
  final String hero;
  final String? villain;

  const SpotPositions({required this.hero, this.villain});
}

/// Holds range information.
class SpotRanges {
  final String? hero;
  final String? villain;

  const SpotRanges({this.hero, this.villain});
}

/// Represents the board cards for each street.
class SpotBoard {
  final List<String>? preflop;
  final List<String>? flop;
  final List<String>? turn;
  final List<String>? river;

  const SpotBoard({this.preflop, this.flop, this.turn, this.river});
}

/// ICM specific data.
class SpotIcm {
  final List<double>? stackDistribution;
  final List<double>? payouts;

  const SpotIcm({this.stackDistribution, this.payouts});
}
