import 'package:collection/collection.dart';

import '../models/streak_recovery_suggestion.dart';
import '../services/booster_suggestion_engine.dart';
import '../services/mistake_tag_insights_service.dart';
import '../services/training_pack_stats_service_v2.dart';
import '../services/training_history_service_v2.dart';
import '../services/training_pack_stats_service.dart';
import '../core/training/library/training_pack_library_v2.dart';
import 'training_stats_service.dart';

class StreakRecoveryRecommender {
  final TrainingStatsService _stats;
  final BoosterSuggestionEngine _booster;

  const StreakRecoveryRecommender({
    TrainingStatsService? stats,
    BoosterSuggestionEngine? booster,
  }) : _stats = stats ?? TrainingStatsService.instance!,
       _booster = booster ?? const BoosterSuggestionEngine();

  Future<List<StreakRecoverySuggestion>> suggest({DateTime? now}) async {
    final last = _stats.lastTrainingDate;
    if (last == null) return [];
    final current = now ?? DateTime.now();
    final lastDay = DateTime(last.year, last.month, last.day);
    if (current.difference(lastDay).inDays <= 1) return [];

    await TrainingPackLibraryV2.instance.loadFromFolder();
    final library = TrainingPackLibraryV2.instance.packs;
    final history = await TrainingHistoryServiceV2.getHistory(limit: 50);
    final improvement = await TrainingPackStatsServiceV2.improvementByTag();
    final insights = await const MistakeTagInsightsService().buildInsights(
      sortByEvLoss: true,
    );

    // Detect most common format
    final formatCount = <String, int>{};
    for (final h in history) {
      final tpl = library.firstWhereOrNull((p) => p.id == h.packId);
      final format = tpl?.meta['format']?.toString().toLowerCase();
      if (tpl != null && format != null && format.isNotEmpty) {
        formatCount.update(format, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    String? topFormat;
    if (formatCount.isNotEmpty) {
      final list = formatCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topFormat = list.first.key;
    }

    final libraryFiltered = topFormat == null
        ? library
        : [
            for (final p in library)
              if (p.meta['format']?.toString().toLowerCase() == topFormat) p,
          ];

    final boosterId = await _booster.suggestBooster(
      library: libraryFiltered,
      improvement: improvement,
      insights: insights,
      history: history,
      now: current,
    );

    final suggestions = <StreakRecoverySuggestion>[];
    if (boosterId != null) {
      final pack = library.firstWhereOrNull((p) => p.id == boosterId);
      final tag = pack?.meta['tag']?.toString();
      suggestions.add(
        StreakRecoverySuggestion(
          title: pack?.name ?? 'Booster',
          packId: boosterId,
          tagFocus: tag,
          ctaText: 'Resume Training',
        ),
      );
    }

    // unfinished pack
    for (final h in history) {
      final p = library.firstWhereOrNull((t) => t.id == h.packId);
      if (p == null) continue;
      final completed = await TrainingPackStatsService.getHandsCompleted(p.id);
      final total = p.spots.isNotEmpty ? p.spots.length : p.spotCount;
      if (completed < total) {
        suggestions.add(
          StreakRecoverySuggestion(
            title: p.name,
            packId: p.id,
            tagFocus: p.tags.isNotEmpty ? p.tags.first : null,
            ctaText: 'Continue Pack',
          ),
        );
        break;
      }
    }

    if (suggestions.isEmpty) {
      suggestions.add(
        const StreakRecoverySuggestion(
          title: 'Spot of the Day',
          packId: 'spot_of_the_day',
          tagFocus: null,
          ctaText: 'Warm Up',
        ),
      );
    }

    return suggestions.take(2).toList();
  }
}
