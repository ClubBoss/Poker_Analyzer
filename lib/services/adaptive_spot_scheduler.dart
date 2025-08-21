import 'dart:async';
import 'dart:math';

import '../models/v2/training_pack_spot.dart';
import 'analytics_service.dart';
import 'user_error_rate_service.dart';

/// Selects training spots based on per-tag error rates with a bit of
/// exploration and safety guards.
class AdaptiveSpotScheduler {
  AdaptiveSpotScheduler({int? seed, Set<String>? packTags})
      : _rng = Random(seed),
        _packTags = packTags?.map((e) => e.toLowerCase()).toSet() ?? <String>{};

  final Random _rng;
  final Set<String> _packTags;

  // Track how often each tag has been surfaced within the current window.
  final Map<String, int> _tagCounts = {};
  int _sinceCoverageReset = 0;

  static const int noRepeatWindow = 5;
  static const int _coverageWindow = 20;
  static const double _base = 1.0;
  static const double _k = 4.0;

  void _bumpTagCounts(TrainingPackSpot spot) {
    for (final t in spot.tags) {
      final tag = t.toLowerCase();
      _tagCounts[tag] = (_tagCounts[tag] ?? 0) + 1;
    }
  }

  /// Picks the next spot from [pool].
  Future<TrainingPackSpot> next({
    required String packId,
    required List<TrainingPackSpot> pool,
    required List<String> recentSpotIds,
    double epsilon = 0.2,
  }) async {
    _sinceCoverageReset++;

    // Coverage guard: every M picks ensure all tags surfaced at least once.
    if (_sinceCoverageReset >= _coverageWindow && _packTags.isNotEmpty) {
      final starved =
          _packTags.where((t) => (_tagCounts[t] ?? 0) == 0).toList();
      if (starved.isNotEmpty) {
        final forced = pool
            .where(
              (s) => s.tags
                  .map((e) => e.toLowerCase())
                  .toSet()
                  .any(starved.contains),
            )
            .toList();
        if (forced.isNotEmpty) {
          final pick = forced[_rng.nextInt(forced.length)];
          _tagCounts.clear();
          _sinceCoverageReset = 0;
          _bumpTagCounts(pick);
          return pick;
        }
      }
      _tagCounts.clear();
      _sinceCoverageReset = 0;
    }

    // Anti-repeat window.
    List<TrainingPackSpot> candidates =
        pool.where((s) => !recentSpotIds.contains(s.id)).toList();
    if (candidates.length < 3) {
      candidates = List<TrainingPackSpot>.from(pool);
    }

    if (candidates.isEmpty) {
      final fallback = pool[_rng.nextInt(pool.length)];
      _bumpTagCounts(fallback);
      return fallback;
    }

    // Exploration step.
    if (_rng.nextDouble() < epsilon) {
      final pick = candidates[_rng.nextInt(candidates.length)];
      _bumpTagCounts(pick);
      return pick;
    }

    // Exploitation: weight by error rates and sample via softmax.
    final weights = <TrainingPackSpot, double>{};
    for (final spot in candidates) {
      final rates = await UserErrorRateService.instance.getRates(
        packId: packId,
        tags: spot.tags.toSet(),
      );
      double maxRate = 0;
      for (final v in rates.values) {
        if (v > maxRate) maxRate = v;
      }
      double w = _base + _k * maxRate;
      w = w.clamp(1.0, 10.0);
      weights[spot] = w;
    }

    final sorted = weights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 =
        sorted.take(3).map((e) => {'spotId': e.key.id, 'w': e.value}).toList();

    final exps = weights.values.map((w) => exp(w)).toList();
    final sumExp = exps.fold<double>(0, (p, e) => p + e);
    final r = _rng.nextDouble();
    double acc = 0;
    TrainingPackSpot? chosen;
    final entries = weights.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      acc += exps[i] / sumExp;
      if (r <= acc) {
        chosen = entries[i].key;
        break;
      }
    }
    chosen ??= entries.last.key;

    // Telemetry.
    unawaited(
      AnalyticsService.instance.logEvent('adaptive_pick', {
        'packId': packId,
        'chosenSpotId': chosen.id,
        'epsilon': epsilon,
        'poolSize': pool.length,
        'top3': top3,
      }),
    );

    _bumpTagCounts(chosen);
    return chosen;
  }
}
