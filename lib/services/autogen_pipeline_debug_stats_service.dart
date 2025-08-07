import 'package:flutter/foundation.dart';

/// Stats for the autogen pipeline debug panel.
class AutogenPipelineStats {
  final int generated;
  final int deduplicated;
  final int curated;
  final int published;

  const AutogenPipelineStats({
    required this.generated,
    required this.deduplicated,
    required this.curated,
    required this.published,
  });

  AutogenPipelineStats copyWith({
    int? generated,
    int? deduplicated,
    int? curated,
    int? published,
  }) {
    return AutogenPipelineStats(
      generated: generated ?? this.generated,
      deduplicated: deduplicated ?? this.deduplicated,
      curated: curated ?? this.curated,
      published: published ?? this.published,
    );
  }
}

/// Service providing live stats for the autogen pipeline.
class AutogenPipelineDebugStatsService {
  AutogenPipelineDebugStatsService._();

  static final ValueNotifier<AutogenPipelineStats> _statsNotifier =
      ValueNotifier(const AutogenPipelineStats(
    generated: 0,
    deduplicated: 0,
    curated: 0,
    published: 0,
  ));

  /// Exposes live stats updates.
  static ValueListenable<AutogenPipelineStats> getLiveStats() => _statsNotifier;

  static void incrementGenerated() {
    _statsNotifier.value =
        _statsNotifier.value.copyWith(generated: _statsNotifier.value.generated + 1);
  }

  static void incrementDeduplicated() {
    _statsNotifier.value = _statsNotifier.value
        .copyWith(deduplicated: _statsNotifier.value.deduplicated + 1);
  }

  static void incrementCurated() {
    _statsNotifier.value =
        _statsNotifier.value.copyWith(curated: _statsNotifier.value.curated + 1);
  }

  static void incrementPublished() {
    _statsNotifier.value =
        _statsNotifier.value.copyWith(published: _statsNotifier.value.published + 1);
  }
}
