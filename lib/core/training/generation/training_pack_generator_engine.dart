import 'package:uuid/uuid.dart';
import '../../../models/v2/training_pack_template_v2.dart';
import '../../../models/v2/training_pack_v2.dart';
import '../../../models/v2/training_pack_spot.dart';
import '../../../services/offline_evaluator_service.dart';

class TrainingPackGeneratorEngine {
  final OfflineEvaluatorService evaluator;
  final Uuid _uuid;
  const TrainingPackGeneratorEngine({
    OfflineEvaluatorService? evaluator,
    Uuid? uuid,
  })  : evaluator = evaluator ?? OfflineEvaluatorService(),
        _uuid = uuid ?? const Uuid();

  Future<TrainingPackV2> generateFromTemplate(
    TrainingPackTemplateV2 template,
  ) async {
    final now = DateTime.now();
    final spots = [
      for (final s in template.spots) TrainingPackSpot.fromJson(s.toJson()),
    ];
    for (final s in spots) {
      await evaluator.evaluate(s, anteBb: template.bb);
      await evaluator.evaluateIcm(s, anteBb: template.bb);
    }
    final pack = TrainingPackV2(
      id: _uuid.v4(),
      sourceTemplateId: template.id,
      name: template.name,
      description: template.description,
      tags: List<String>.from(template.tags),
      type: template.type,
      spots: spots,
      spotCount: spots.length,
      generatedAt: now,
      gameType: template.gameType,
      bb: template.bb,
      positions: List<String>.from(template.positions),
      difficulty: template.meta['difficulty'] is int
          ? template.meta['difficulty'] as int
          : template.spotCount ~/ 10 + 1,
      meta: Map<String, dynamic>.from(template.meta),
    );
    pack.meta['generatedAt'] = now.toIso8601String();
    pack.meta['sourceTemplateId'] = template.id;
    _recountCoverage(pack);
    return pack;
  }

  void _recountCoverage(TrainingPackV2 pack) {
    var ev = 0;
    var icm = 0;
    var total = 0;
    for (final s in pack.spots) {
      final w = s.priority;
      total += w;
      if (s.heroEv != null) ev += w;
      if (s.heroIcmEv != null) icm += w;
    }
    pack.meta['evCovered'] = ev;
    pack.meta['icmCovered'] = icm;
    pack.meta['totalWeight'] = total;
  }
}
