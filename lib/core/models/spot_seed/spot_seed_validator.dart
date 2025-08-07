import 'unified_spot_seed_format.dart';
import 'seed_issue.dart';

/// Preferences controlling validator behaviour.
class SpotSeedValidatorPreferences {
  final bool allowUnknownTags;
  final int? maxComboCount;
  final String? requireRangesForStreets;

  const SpotSeedValidatorPreferences({
    this.allowUnknownTags = true,
    this.maxComboCount,
    this.requireRangesForStreets,
  });
}

/// Validates [SpotSeed] instances.
class SpotSeedValidator {
  final SpotSeedValidatorPreferences prefs;

  const SpotSeedValidator({SpotSeedValidatorPreferences? preferences})
    : prefs = preferences ?? const SpotSeedValidatorPreferences();

  /// Returns a list of issues found within [seed].
  List<SeedIssue> validate(SpotSeed seed) {
    final issues = <SeedIssue>[];

    if (seed.stackBB <= 0) {
      issues.add(
        const SeedIssue(
          code: 'stackBB_non_positive',
          severity: 'error',
          message: 'stackBB must be greater than 0',
          path: ['stackBB'],
        ),
      );
    }

    if (seed.positions.villain != null &&
        seed.positions.villain == seed.positions.hero) {
      issues.add(
        const SeedIssue(
          code: 'positions_conflict',
          severity: 'error',
          message: 'hero and villain positions cannot match',
          path: ['positions'],
        ),
      );
    }

    // Tag normalization check
    final seen = <String>{};
    for (final tag in seed.tags) {
      final lower = tag.toLowerCase();
      if (tag != lower) {
        issues.add(
          SeedIssue(
            code: 'tag_not_lowercase',
            severity: 'warn',
            message: 'tag `$tag` should be lowercase',
            path: ['tags'],
          ),
        );
      }
      if (!seen.add(lower)) {
        issues.add(
          SeedIssue(
            code: 'tag_duplicate',
            severity: 'warn',
            message: 'duplicate tag `$tag`',
            path: ['tags'],
          ),
        );
      }
    }

    // Range requirement based on board presence
    if (prefs.requireRangesForStreets != null) {
      final req = prefs.requireRangesForStreets!;
      final hasBoardBeyondPreflop =
          (req == 'flop' && (seed.board.flop?.isNotEmpty ?? false)) ||
          (req == 'turn' && (seed.board.turn?.isNotEmpty ?? false)) ||
          (req == 'river' && (seed.board.river?.isNotEmpty ?? false));
      if (hasBoardBeyondPreflop) {
        if (seed.ranges.hero == null || seed.ranges.villain == null) {
          issues.add(
            const SeedIssue(
              code: 'ranges_missing',
              severity: 'error',
              message: 'ranges required for specified streets',
              path: ['ranges'],
            ),
          );
        }
      }
    }

    if (seed.icm != null && seed.gameType != 'tournament') {
      issues.add(
        const SeedIssue(
          code: 'icm_not_allowed',
          severity: 'error',
          message: 'ICM data only valid for tournaments',
          path: ['icm'],
        ),
      );
    }

    return issues;
  }
}
