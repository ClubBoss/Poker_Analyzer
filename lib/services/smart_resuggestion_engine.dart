import 'package:collection/collection.dart';

import '../models/v2/training_pack_template_v2.dart';
import 'pack_library_loader_service.dart';
import 'pack_suggestion_analytics_engine.dart';
import 'suggestion_cooldown_manager.dart';
import 'session_log_service.dart';
import 'suggested_training_packs_history_service.dart';
import 'suggested_weak_tag_pack_service.dart';

/// Resuggests packs that previously showed engagement but were not completed.
class SmartReSuggestionEngine {
  final SessionLogService logs;
  final List<TrainingPackTemplateV2>? _libraryOverride;
  final SuggestedWeakTagPackService _weakTagService;

  SmartReSuggestionEngine({
    required this.logs,
    List<TrainingPackTemplateV2>? library,
    SuggestedWeakTagPackService? weakTagService,
  }) : _libraryOverride = library,
       _weakTagService = weakTagService ?? const SuggestedWeakTagPackService();

  /// Returns the next suggested pack without logging or updating cooldowns.
  Future<TrainingPackTemplateV2?> previewNext() async {
    final analytics = PackSuggestionAnalyticsEngine(logs: logs);
    final stats = await analytics.getStats();

    await PackLibraryLoaderService.instance.loadLibrary();
    final library =
        _libraryOverride ?? PackLibraryLoaderService.instance.library;

    final entries = <MapEntry<TrainingPackTemplateV2, PackEngagementStats>>[];
    for (final s in stats) {
      if (s.shownCount < 2 || s.completedCount > 0) continue;
      final tpl = library.firstWhereOrNull((p) => p.id == s.packId);
      if (tpl == null) continue;
      if (await SuggestedTrainingPacksHistoryService.wasRecentlySuggested(
        tpl.id,
        within: const Duration(days: 14),
      )) {
        continue;
      }
      if (await SuggestionCooldownManager.isUnderCooldown(
        tpl.id,
        cooldown: const Duration(days: 14),
      )) {
        continue;
      }
      entries.add(MapEntry(tpl, s));
    }

    if (entries.isNotEmpty) {
      entries.sort((a, b) {
        final cmp = b.value.startedCount.compareTo(a.value.startedCount);
        if (cmp != 0) return cmp;
        return b.value.shownCount.compareTo(a.value.shownCount);
      });
      return entries.first.key;
    }

    final fallback = await _weakTagService.suggestPack();
    return fallback.pack;
  }

  /// Suggests a pack to retry based on past suggestions and engagement stats.
  Future<TrainingPackTemplateV2?> suggestNext() async {
    final analytics = PackSuggestionAnalyticsEngine(logs: logs);
    final stats = await analytics.getStats();

    await PackLibraryLoaderService.instance.loadLibrary();
    final library =
        _libraryOverride ?? PackLibraryLoaderService.instance.library;

    final entries = <MapEntry<TrainingPackTemplateV2, PackEngagementStats>>[];
    for (final s in stats) {
      if (s.shownCount < 2 || s.completedCount > 0) continue;
      final tpl = library.firstWhereOrNull((p) => p.id == s.packId);
      if (tpl == null) continue;
      if (await SuggestedTrainingPacksHistoryService.wasRecentlySuggested(
        tpl.id,
        within: const Duration(days: 14),
      )) {
        continue;
      }
      if (await SuggestionCooldownManager.isUnderCooldown(
        tpl.id,
        cooldown: const Duration(days: 14),
      )) {
        continue;
      }
      entries.add(MapEntry(tpl, s));
    }

    if (entries.isNotEmpty) {
      entries.sort((a, b) {
        final cmp = b.value.startedCount.compareTo(a.value.startedCount);
        if (cmp != 0) return cmp;
        return b.value.shownCount.compareTo(a.value.shownCount);
      });
      final selected = entries.first.key;
      await SuggestionCooldownManager.markSuggested(selected.id);
      await SuggestedTrainingPacksHistoryService.logSuggestion(
        packId: selected.id,
        source: 'resuggestion_engine',
      );
      return selected;
    }

    final fallback = await _weakTagService.suggestPack();
    return fallback.pack;
  }
}
