import '../models/training_pack_model.dart';
import '../models/v2/training_pack_spot.dart';
import 'spot_fingerprint_generator.dart';

/// Represents a detected issue in a [TrainingPackModel].
class PackQualityIssue {
  final String id;
  final String description;
  final String severity;
  final String? fixSuggestion;

  PackQualityIssue({
    required this.id,
    required this.description,
    required this.severity,
    this.fixSuggestion,
  });
}

/// Analyzes training packs for common structural or content problems.
class PackQualityInspectorService {
  PackQualityInspectorService._({SpotFingerprintGenerator? fingerprint})
    : _fingerprint = fingerprint ?? const SpotFingerprintGenerator();

  static final PackQualityInspectorService instance =
      PackQualityInspectorService._();

  final SpotFingerprintGenerator _fingerprint;

  /// Returns a list of [PackQualityIssue]s detected in [pack].
  List<PackQualityIssue> analyzePack(TrainingPackModel pack) {
    final issues = <PackQualityIssue>[];
    if (pack.spots.isEmpty) {
      return issues;
    }

    // Tag usage analysis
    final tagCounts = <String, int>{};
    var totalTags = 0;
    for (final spot in pack.spots) {
      for (final tag in spot.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        totalTags++;
      }
    }
    if (totalTags > 0) {
      final mostUsed = tagCounts.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      final ratio = mostUsed.value / totalTags;
      if (ratio > 0.4) {
        issues.add(
          PackQualityIssue(
            id: 'overused_tag',
            description:
                'Tag "${mostUsed.key}" used in ${(ratio * 100).toStringAsFixed(1)}% of spots',
            severity: 'warning',
            fixSuggestion: 'Diversify tags to cover more skills',
          ),
        );
      }
    }

    // Theory linkage analysis
    var linked = 0;
    for (final spot in pack.spots) {
      if (spot.theoryRefs.isNotEmpty ||
          spot.theoryId != null ||
          spot.inlineLessonId != null) {
        linked++;
      }
    }
    final theoryRatio = linked / pack.spots.length;
    if (theoryRatio < 0.3) {
      issues.add(
        PackQualityIssue(
          id: 'missing_theory_links',
          description: 'Most spots lack theory references',
          severity: 'warning',
          fixSuggestion: 'Link more spots to relevant theory lessons',
        ),
      );
    }

    // Board diversity analysis
    final boards = <String>{};
    for (final spot in pack.spots) {
      if (spot.board.isNotEmpty) {
        boards.add(spot.board.join());
      }
    }
    final boardRatio = boards.length / pack.spots.length;
    if (boardRatio < 0.5) {
      issues.add(
        PackQualityIssue(
          id: 'low_board_diversity',
          description: 'Many spots share identical boards',
          severity: 'info',
          fixSuggestion: 'Include a wider variety of board textures',
        ),
      );
    }

    // Duplicate/Excessive repetition analysis
    final seen = <String, int>{};
    for (final spot in pack.spots) {
      final fp = _fingerprint.generate(spot);
      seen[fp] = (seen[fp] ?? 0) + 1;
    }
    var repeatCount = 0;
    for (final v in seen.values) {
      if (v > 1) repeatCount += v - 1;
    }
    final repeatRatio = repeatCount / pack.spots.length;
    if (repeatRatio > 0.1) {
      issues.add(
        PackQualityIssue(
          id: 'duplicate_spots',
          description:
              '${(repeatRatio * 100).toStringAsFixed(1)}% of spots appear to be duplicates',
          severity: 'warning',
          fixSuggestion: 'Remove or vary repetitive spots',
        ),
      );
    }

    // Spot count check
    const minSpots = 10;
    const maxSpots = 100;
    if (pack.spots.length < minSpots) {
      issues.add(
        PackQualityIssue(
          id: 'too_few_spots',
          description: 'Pack has only ${pack.spots.length} spots',
          severity: 'info',
          fixSuggestion: 'Add more spots for meaningful training',
        ),
      );
    } else if (pack.spots.length > maxSpots) {
      issues.add(
        PackQualityIssue(
          id: 'too_many_spots',
          description: 'Pack has ${pack.spots.length} spots',
          severity: 'info',
          fixSuggestion: 'Reduce pack size for better focus',
        ),
      );
    }

    return issues;
  }

  /// Returns a new [TrainingPackModel] with simple fixes applied.
  TrainingPackModel autoFix(TrainingPackModel pack) {
    final seen = <String>{};
    final deduped = <TrainingPackSpot>[];
    for (final spot in pack.spots) {
      final fp = _fingerprint.generate(spot);
      if (seen.add(fp)) {
        deduped.add(spot);
      }
    }
    return TrainingPackModel(
      id: pack.id,
      title: pack.title,
      spots: deduped,
      tags: List<String>.from(pack.tags),
      metadata: Map<String, dynamic>.from(pack.metadata),
    );
  }
}
