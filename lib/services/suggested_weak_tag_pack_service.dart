import 'package:collection/collection.dart';

import '../models/v2/training_pack_template_v2.dart';
import 'suggestion_cooldown_manager.dart';
import 'pack_library_loader_service.dart';
import 'weak_tag_detector_service.dart';
import 'training_tag_performance_engine.dart';
import 'suggested_training_packs_history_service.dart';

class SuggestedWeakTagPackResult {
  final TrainingPackTemplateV2? pack;
  final bool isFallback;
  const SuggestedWeakTagPackResult({
    required this.pack,
    required this.isFallback,
  });
}

class SuggestedWeakTagPackService {
  final List<TrainingPackTemplateV2>? _libraryOverride;
  final Future<List<TagPerformance>> Function()? _detectWeakTags;
  const SuggestedWeakTagPackService({
    List<TrainingPackTemplateV2>? library,
    Future<List<TagPerformance>> Function()? detectWeakTags,
  }) : _libraryOverride = library,
       _detectWeakTags = detectWeakTags;

  Future<SuggestedWeakTagPackResult> suggestPack() async {
    final weak = _detectWeakTags != null
        ? await _detectWeakTags()
        : await WeakTagDetectorService.detectWeakTags();
    await PackLibraryLoaderService.instance.loadLibrary();
    final library =
        _libraryOverride ?? PackLibraryLoaderService.instance.library;

    for (final t in weak) {
      final pack = library.firstWhereOrNull((p) => p.tags.contains(t.tag));
      if (pack != null &&
          !await SuggestionCooldownManager.isUnderCooldown(pack.id)) {
        await SuggestedTrainingPacksHistoryService.logSuggestion(
          packId: pack.id,
          source: 'weak_tag',
        );
        return SuggestedWeakTagPackResult(pack: pack, isFallback: false);
      }
    }

    final fallback = await _findFallback(library);
    return SuggestedWeakTagPackResult(pack: fallback, isFallback: true);
  }

  Future<TrainingPackTemplateV2?> _findFallback(
    List<TrainingPackTemplateV2> library,
  ) async {
    for (final p in library) {
      if (p.tags.contains('fundamentals') &&
          !await SuggestionCooldownManager.isUnderCooldown(p.id)) {
        await SuggestedTrainingPacksHistoryService.logSuggestion(
          packId: p.id,
          source: 'weak_tag',
        );
        return p;
      }
    }
    for (final p in library) {
      if (p.tags.contains('starter') &&
          !await SuggestionCooldownManager.isUnderCooldown(p.id)) {
        await SuggestedTrainingPacksHistoryService.logSuggestion(
          packId: p.id,
          source: 'weak_tag',
        );
        return p;
      }
    }
    final sorted = [...library]
      ..sort((a, b) {
        final pa = (a.meta['popularity'] as num?)?.toDouble() ?? 0;
        final pb = (b.meta['popularity'] as num?)?.toDouble() ?? 0;
        return pb.compareTo(pa);
      });
    for (final p in sorted) {
      if (!await SuggestionCooldownManager.isUnderCooldown(p.id)) {
        await SuggestedTrainingPacksHistoryService.logSuggestion(
          packId: p.id,
          source: 'weak_tag',
        );
        return p;
      }
    }
    return null;
  }
}
