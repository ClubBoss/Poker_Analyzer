import '../models/v2/training_pack_template_v2.dart';
import 'suggestion_cooldown_manager.dart';
import 'pack_library_loader_service.dart';
import 'training_gap_detector_service.dart';
import 'training_tag_performance_engine.dart';
import 'suggested_training_packs_history_service.dart';

class SkillRecoveryPackEngine {
  const SkillRecoveryPackEngine._();

  /// Suggests a training pack aimed at refreshing dormant skills.
  ///
  /// [excludedPackIds] prevents already suggested packs from being returned.
  /// [library] and [detectDormantTags] are used for testing.
  static Future<TrainingPackTemplateV2?> suggestRecoveryPack({
    Set<String>? excludedPackIds,
    List<TrainingPackTemplateV2>? library,
    Future<List<TagPerformance>> Function()? detectDormantTags,
  }) async {
    final dormant = detectDormantTags != null
        ? await detectDormantTags()
        : await TrainingGapDetectorService.detectDormantTags(limit: 3);

    await PackLibraryLoaderService.instance.loadLibrary();
    final lib = library ?? PackLibraryLoaderService.instance.library;
    final exclude = excludedPackIds ?? <String>{};

    for (final item in dormant) {
      final tag = item.tag.toLowerCase();
      final candidates = <TrainingPackTemplateV2>[];
      for (final p in lib) {
        if (exclude.contains(p.id)) continue;
        final tags = {for (final t in p.tags) t.toLowerCase()};
        final metaTags = p.meta['tags'];
        if (metaTags is List) {
          tags.addAll(metaTags.map((e) => e.toString().toLowerCase()));
        }
        final focusTags = p.meta['focusTags'];
        if (focusTags is List) {
          tags.addAll(focusTags.map((e) => e.toString().toLowerCase()));
        }
        final focusTag = p.meta['focusTag'];
        if (focusTag is String) tags.add(focusTag.toLowerCase());
        if (tags.contains(tag) &&
            !await SuggestionCooldownManager.isUnderCooldown(p.id)) {
          candidates.add(p);
        }
      }

      if (candidates.isEmpty) continue;

      int score(TrainingPackTemplateV2 p) {
        var s = 0;
        if (p.meta['suggested'] == true) s += 2;
        if (p.meta['starter'] == true) s += 1;
        return s;
      }

      candidates.sort((a, b) => score(b).compareTo(score(a)));
      final selected = candidates.first;
      await SuggestedTrainingPacksHistoryService.logSuggestion(
        packId: selected.id,
        source: 'skill_recovery',
      );
      return selected;
    }

    return await _findFallback(lib, exclude);
  }

  static Future<TrainingPackTemplateV2?> _findFallback(
    List<TrainingPackTemplateV2> library,
    Set<String> exclude,
  ) async {
    for (final p in library) {
      if (exclude.contains(p.id)) continue;
      if (p.tags.map((e) => e.toLowerCase()).contains('fundamentals') &&
          !await SuggestionCooldownManager.isUnderCooldown(p.id)) {
        await SuggestedTrainingPacksHistoryService.logSuggestion(
          packId: p.id,
          source: 'skill_recovery',
        );
        return p;
      }
    }
    for (final p in library) {
      if (exclude.contains(p.id)) continue;
      if (p.tags.map((e) => e.toLowerCase()).contains('starter') &&
          !await SuggestionCooldownManager.isUnderCooldown(p.id)) {
        await SuggestedTrainingPacksHistoryService.logSuggestion(
          packId: p.id,
          source: 'skill_recovery',
        );
        return p;
      }
    }
    final sorted =
        [
          for (final p in library)
            if (!exclude.contains(p.id)) p,
        ]..sort((a, b) {
          final pa = (a.meta['popularity'] as num?)?.toDouble() ?? 0;
          final pb = (b.meta['popularity'] as num?)?.toDouble() ?? 0;
          return pb.compareTo(pa);
        });
    for (final p in sorted) {
      if (!await SuggestionCooldownManager.isUnderCooldown(p.id)) {
        await SuggestedTrainingPacksHistoryService.logSuggestion(
          packId: p.id,
          source: 'skill_recovery',
        );
        return p;
      }
    }
    return null;
  }
}
