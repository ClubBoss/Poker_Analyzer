import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_preview_spot.dart';
import 'training_spot_generator_service.dart';
import 'constraint_resolver_engine.dart';
import 'dart:math';

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
        Map<String, dynamic>.from(dyn));
    final params = SpotGenerationParams(
      position: m['position']?.toString() ?? 'btn',
      villainAction: m['villainAction']?.toString() ?? '',
      handGroup: [
        for (final g in (m['handGroup'] as List? ?? [])) g.toString()
      ],
      count: min(count, (m['count'] as num?)?.toInt() ?? count),
      boardFilter: m['boardFilter'] is Map
          ? Map<String, dynamic>.from(m['boardFilter'])
          : null,
      targetStreet: m['targetStreet']?.toString() ?? 'flop',
      boardStages: (m['boardStages'] as num?)?.toInt(),
    );
    final spots =
        _generator.generate(params, dynamicParams: m);
    return [
      for (final s in spots)
        TrainingPackPreviewSpot(
          hand: s.playerCards[s.heroIndex]
              .map((c) => c.toString())
              .join(' '),
          position: s.heroPosition ?? params.position,
          action: params.villainAction,
        )
    ];
  }
}
