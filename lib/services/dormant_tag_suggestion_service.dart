import 'package:collection/collection.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'pack_library_loader_service.dart';
import 'training_gap_detector_service.dart';
import 'pack_suggestion_cooldown_service.dart';
import 'suggested_training_packs_history_service.dart';

class DormantTagSuggestionService {
  const DormantTagSuggestionService();

  Future<TrainingPackTemplateV2?> suggestPack() async {
    final dormant = await TrainingGapDetectorService.detectDormantTags(limit: 1);
    if (dormant.isEmpty) return null;
    final tag = dormant.first.tag;

    await PackLibraryLoaderService.instance.loadLibrary();
    final library = PackLibraryLoaderService.instance.library;
    final tpl = library.firstWhereOrNull(
      (p) => p.tags.contains(tag) || p.meta['focusTag'] == tag,
    );
    if (tpl == null) return null;
    if (await PackSuggestionCooldownService.isRecentlySuggested(tpl.id)) {
      return null;
    }
    await PackSuggestionCooldownService.markAsSuggested(tpl.id);
    await SuggestedTrainingPacksHistoryService.logSuggestion(
      packId: tpl.id,
      source: 'dormant_tag',
      tagContext: tag,
    );
    return tpl;
  }
}
