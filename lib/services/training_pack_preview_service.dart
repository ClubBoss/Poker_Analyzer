import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_preview_spot.dart';
import 'training_spot_generator_service.dart';
import 'constraint_resolver_engine.dart';
import 'dart:math';
import '../helpers/board_filtering_params_builder.dart';
import 'hand_group_tag_library_service.dart';

class TrainingPackPreviewService {
  final TrainingSpotGeneratorService _generator;

  TrainingPackPreviewService({TrainingSpotGeneratorService? generator})
      : _generator = generator ?? TrainingSpotGeneratorService();

  List<TrainingPackPreviewSpot> getPreviewSpots(
    TrainingPackTemplateV2 tpl, {
    int count = 5,
  }) {
    final dyn = tpl.meta['dynamicParams'];
    if (dyn is! Map) return [];
    final m = ConstraintResolverEngine.normalizeParams(
      Map<String, dynamic>.from(dyn),
    );
    final tagList =
        (m['handGroupTags'] as List?)?.map((e) => e.toString()).toList();
    if (tagList != null && tagList.isNotEmpty) {
      final expanded = HandGroupTagLibraryService.expandTags(tagList);
      final existing =
          (m['handGroup'] as List? ?? []).map((e) => e.toString()).toList();
      m['handGroup'] = [...existing, ...expanded];
    }
    Map<String, dynamic>? boardFilter;
    final tags = (m['boardTextureTags'] as List? ?? m['textureTags'] as List?)
        ?.cast<String>();
    if (tags != null && tags.isNotEmpty) {
      boardFilter = BoardFilteringParamsBuilder.build(tags);
    }
    if (m['boardFilter'] is Map) {
      boardFilter = {
        ...?boardFilter,
        ...Map<String, dynamic>.from(m['boardFilter']),
      };
    }
    if (boardFilter != null) {
      m['boardFilter'] = boardFilter;
    }
    final params = SpotGenerationParams(
      position: m['position']?.toString() ?? 'btn',
      villainAction: m['villainAction']?.toString() ?? '',
      handGroup: [
        for (final g in (m['handGroup'] as List? ?? [])) g.toString(),
      ],
      count: min(count, (m['count'] as num?)?.toInt() ?? count),
      boardFilter: boardFilter,
      targetStreet: m['targetStreet']?.toString() ?? 'flop',
      boardStages: (m['boardStages'] as num?)?.toInt(),
    );
    final spots = _generator.generate(params, dynamicParams: m);
    return [
      for (final s in spots)
        TrainingPackPreviewSpot(
          hand: s.playerCards[s.heroIndex].map((c) => c.toString()).join(' '),
          position: s.heroPosition ?? params.position,
          action: params.villainAction,
        ),
    ];
  }
}
