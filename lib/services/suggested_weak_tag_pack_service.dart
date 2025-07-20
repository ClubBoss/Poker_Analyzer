import 'package:collection/collection.dart';

import '../models/v2/training_pack_template_v2.dart';
import 'pack_library_loader_service.dart';
import 'weak_tag_detector_service.dart';
import 'training_tag_performance_engine.dart';

class SuggestedWeakTagPackResult {
  final TrainingPackTemplateV2? pack;
  final bool isFallback;
  const SuggestedWeakTagPackResult({required this.pack, required this.isFallback});
}

class SuggestedWeakTagPackService {
  final List<TrainingPackTemplateV2>? _libraryOverride;
  final Future<List<TagPerformance>> Function()? _detectWeakTags;
  const SuggestedWeakTagPackService({
    List<TrainingPackTemplateV2>? library,
    Future<List<TagPerformance>> Function()? detectWeakTags,
  })  : _libraryOverride = library,
        _detectWeakTags = detectWeakTags;

  Future<SuggestedWeakTagPackResult> suggestPack() async {
    final weak = _detectWeakTags != null
        ? await _detectWeakTags!()
        : await WeakTagDetectorService.detectWeakTags();
    await PackLibraryLoaderService.instance.loadLibrary();
    final library = _libraryOverride ?? PackLibraryLoaderService.instance.library;

    for (final t in weak) {
      final pack = library.firstWhereOrNull((p) => p.tags.contains(t.tag));
      if (pack != null) {
        return SuggestedWeakTagPackResult(pack: pack, isFallback: false);
      }
    }

    final fallback = _findFallback(library);
    return SuggestedWeakTagPackResult(pack: fallback, isFallback: true);
  }

  TrainingPackTemplateV2? _findFallback(List<TrainingPackTemplateV2> library) {
    final fund = library.firstWhereOrNull((p) => p.tags.contains('fundamentals'));
    if (fund != null) return fund;
    final starter = library.firstWhereOrNull((p) => p.tags.contains('starter'));
    if (starter != null) return starter;
    final sorted = [...library]
      ..sort((a, b) {
        final pa = (a.meta['popularity'] as num?)?.toDouble() ?? 0;
        final pb = (b.meta['popularity'] as num?)?.toDouble() ?? 0;
        return pb.compareTo(pa);
      });
    return sorted.firstOrNull;
  }
}
