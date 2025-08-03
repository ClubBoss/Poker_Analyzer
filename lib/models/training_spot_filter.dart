import 'training_spot.dart';

class TrainingSpotFilter {
  final List<String> tags;
  final List<String> positions;
  final int? minDifficulty;
  final int? maxDifficulty;

  const TrainingSpotFilter({
    this.tags = const [],
    this.positions = const [],
    this.minDifficulty,
    this.maxDifficulty,
  });

  factory TrainingSpotFilter.fromMap(Map<String, dynamic> map) {
    return TrainingSpotFilter(
      tags: map['tags'] is List ? List<String>.from(map['tags']) : const [],
      positions:
          map['positions'] is List ? List<String>.from(map['positions']) : const [],
      minDifficulty: map['minDifficulty'] is int
          ? map['minDifficulty'] as int
          : (map['minDifficulty'] as num?)?.toInt(),
      maxDifficulty: map['maxDifficulty'] is int
          ? map['maxDifficulty'] as int
          : (map['maxDifficulty'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
        if (tags.isNotEmpty) 'tags': tags,
        if (positions.isNotEmpty) 'positions': positions,
        if (minDifficulty != null) 'minDifficulty': minDifficulty,
        if (maxDifficulty != null) 'maxDifficulty': maxDifficulty,
      };

  bool get isEmpty =>
      tags.isEmpty && positions.isEmpty && minDifficulty == null && maxDifficulty == null;

  bool matches(TrainingSpot spot) {
    if (tags.isNotEmpty && !tags.every((t) => spot.tags.contains(t))) {
      return false;
    }
    if (positions.isNotEmpty) {
      final heroPos = spot.positions.isNotEmpty ? spot.positions[spot.heroIndex] : '';
      if (!positions.contains(heroPos)) return false;
    }
    if (minDifficulty != null && spot.difficulty < minDifficulty!) return false;
    if (maxDifficulty != null && spot.difficulty > maxDifficulty!) return false;
    return true;
  }
}
