import 'package:collection/collection.dart';

import '../models/v2/training_pack_template_v2.dart';
import 'pack_library_loader_service.dart';
import 'training_gap_detector_service.dart';
import 'training_tag_performance_engine.dart';

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
      final candidates = lib.where((p) {
        if (exclude.contains(p.id)) return false;
        final tags = {
          for (final t in p.tags) t.toLowerCase(),
        };
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
        return tags.contains(tag);
      }).toList();

      if (candidates.isEmpty) continue;

      int score(TrainingPackTemplateV2 p) {
        var s = 0;
        if (p.meta['suggested'] == true) s += 2;
        if (p.meta['starter'] == true) s += 1;
        return s;
      }

      candidates.sort((a, b) => score(b).compareTo(score(a)));
      return candidates.first;
    }

    return _findFallback(lib, exclude);
  }

  static TrainingPackTemplateV2? _findFallback(
    List<TrainingPackTemplateV2> library,
    Set<String> exclude,
  ) {
    final fund = library.firstWhereOrNull(
      (p) =>
          !exclude.contains(p.id) &&
          p.tags.map((e) => e.toLowerCase()).contains('fundamentals'),
    );
    if (fund != null) return fund;
    final starter = library.firstWhereOrNull(
      (p) =>
          !exclude.contains(p.id) &&
          p.tags.map((e) => e.toLowerCase()).contains('starter'),
    );
    if (starter != null) return starter;
    final sorted = [
      for (final p in library)
        if (!exclude.contains(p.id)) p
    ]..sort((a, b) {
        final pa = (a.meta['popularity'] as num?)?.toDouble() ?? 0;
        final pb = (b.meta['popularity'] as num?)?.toDouble() ?? 0;
        return pb.compareTo(pa);
      });
    return sorted.firstOrNull;
  }
}
