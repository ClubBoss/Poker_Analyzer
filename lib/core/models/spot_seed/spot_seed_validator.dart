import 'unified_spot_seed_format.dart';
import 'seed_issue.dart';

/// Preferences controlling validator behaviour.
class SpotSeedValidatorPreferences {
  final bool allowUnknownTags;
  final int? maxComboCount;
  final List<String> requireRangesForStreets;
  final bool validateBoardLength;
  final bool validatePositionConsistency;

  const SpotSeedValidatorPreferences({
    this.allowUnknownTags = true,
    this.maxComboCount,
    this.requireRangesForStreets = const <String>[],
    this.validateBoardLength = false,
    this.validatePositionConsistency = false,
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
    if (prefs.requireRangesForStreets.isNotEmpty) {
      final streets = prefs.requireRangesForStreets
          .map((s) => s.toLowerCase())
          .toSet();
      final needsRanges =
          (streets.contains('flop') &&
              (seed.board.flop?.isNotEmpty ?? false)) ||
          (streets.contains('turn') &&
              (seed.board.turn?.isNotEmpty ?? false)) ||
          (streets.contains('river') &&
              (seed.board.river?.isNotEmpty ?? false));
      if (needsRanges &&
          (seed.ranges.hero == null || seed.ranges.villain == null)) {
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

    // Board length validation
    if (prefs.validateBoardLength) {
      if (seed.board.flop != null && seed.board.flop!.length != 3) {
        issues.add(
          const SeedIssue(
            code: 'flop_length',
            severity: 'error',
            message: 'flop must have 3 cards',
            path: ['board', 'flop'],
          ),
        );
      }
      if (seed.board.turn != null && seed.board.turn!.length != 1) {
        issues.add(
          const SeedIssue(
            code: 'turn_length',
            severity: 'error',
            message: 'turn must have 1 card',
            path: ['board', 'turn'],
          ),
        );
      }
      if (seed.board.river != null && seed.board.river!.length != 1) {
        issues.add(
          const SeedIssue(
            code: 'river_length',
            severity: 'error',
            message: 'river must have 1 card',
            path: ['board', 'river'],
          ),
        );
      }
    }

    // Position consistency validation
    if (prefs.validatePositionConsistency) {
      final hero = seed.positions.hero.toUpperCase();
      final villain = seed.positions.villain?.toUpperCase();
      const allowed = {'BTN', 'SB', 'BB'};
      if (!allowed.contains(hero) ||
          (villain != null && !allowed.contains(villain))) {
        issues.add(
          const SeedIssue(
            code: 'position_invalid',
            severity: 'error',
            message: 'positions must be BTN, SB or BB',
            path: ['positions'],
          ),
        );
      } else if (villain != null) {
        final pairs = {
          'BTN': {'SB', 'BB'},
          'SB': {'BTN', 'BB'},
          'BB': {'BTN', 'SB'},
        };
        if (!(pairs[hero]?.contains(villain) ?? false)) {
          issues.add(
            const SeedIssue(
              code: 'position_mismatch',
              severity: 'error',
              message: 'hero/villain positions inconsistent',
              path: ['positions'],
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
