import '../core/training/library/training_pack_library_v2.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/pack_ux_metadata.dart';
import '../models/game_type.dart';
import '../core/training/engine/training_type_engine.dart';

class TrainingPackLibraryMetadataEnricher {
  final TrainingPackLibraryV2 library;

  TrainingPackLibraryMetadataEnricher({TrainingPackLibraryV2? library})
      : library = library ?? TrainingPackLibraryV2.instance;

  /// Iterates over all packs and enriches each with UX metadata.
  void enrichAll() {
    for (final pack in library.packs) {
      pack.meta['level'] = _inferLevel(pack).name;
      pack.meta['topic'] = _inferTopic(pack).name;
      pack.meta['format'] = _inferFormat(pack).name;
      pack.meta['complexity'] = _inferComplexity(pack).name;
    }
  }

  TrainingPackLevel _inferLevel(TrainingPackTemplateV2 p) {
    final skill = p.meta['skillLevel']?.toString().toLowerCase();
    if (skill == 'beginner') return TrainingPackLevel.beginner;
    if (skill == 'advanced') return TrainingPackLevel.advanced;
    if (skill == 'intermediate') return TrainingPackLevel.intermediate;
    final tags = p.tags.map((t) => t.toLowerCase());
    if (tags.contains('starter') || tags.contains('beginner')) {
      return TrainingPackLevel.beginner;
    }
    if (tags.contains('advanced')) return TrainingPackLevel.advanced;
    return TrainingPackLevel.intermediate;
  }

  TrainingPackTopic _inferTopic(TrainingPackTemplateV2 p) {
    final tags = p.tags.map((t) => t.toLowerCase()).toList();
    if (tags.any((t) => t.contains('3bet'))) {
      return TrainingPackTopic.threeBet;
    }
    if (tags.any((t) => t.contains('open'))) {
      return TrainingPackTopic.openFold;
    }
    if (tags.any((t) => t.contains('push'))) {
      return TrainingPackTopic.pushFold;
    }
    if (tags.any(
      (t) =>
          t.contains('flop') ||
          t.contains('turn') ||
          t.contains('river') ||
          t.contains('postflop'),
    )) {
      return TrainingPackTopic.postflop;
    }
    if (p.trainingType == TrainingType.postflop) {
      return TrainingPackTopic.postflop;
    }
    return TrainingPackTopic.pushFold;
  }

  TrainingPackFormat _inferFormat(TrainingPackTemplateV2 p) {
    return p.gameType == GameType.cash
        ? TrainingPackFormat.cash
        : TrainingPackFormat.tournament;
  }

  TrainingPackComplexity _inferComplexity(TrainingPackTemplateV2 p) {
    final tags = p.tags.map((t) => t.toLowerCase());
    if (tags.contains('icm') || p.meta['icm'] == true) {
      return TrainingPackComplexity.icm;
    }
    if ((p.targetStreet != null &&
            p.targetStreet!.toLowerCase() != 'preflop') ||
        p.spotCount > 20) {
      return TrainingPackComplexity.multiStreet;
    }
    return TrainingPackComplexity.simple;
  }
}
