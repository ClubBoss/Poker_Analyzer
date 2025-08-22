import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/game_type.dart';
import '../core/training/engine/training_type_engine.dart';
import 'pack_novelty_guard_service.dart';

/// Synthesizes small assessment packs targeting weakest tags.
class AssessmentPackSynthesizer {
  final PackNoveltyGuardService noveltyGuard;

  AssessmentPackSynthesizer({PackNoveltyGuardService? noveltyGuard})
    : noveltyGuard = noveltyGuard ?? const PackNoveltyGuardService();

  Future<TrainingPackTemplateV2> createAssessment({
    required List<String> tags,
    int size = 6,
    required String clusterId,
    required String themeName,
  }) async {
    var currentSize = size;
    TrainingPackTemplateV2? pack;
    for (var attempt = 0; attempt < 2; attempt++) {
      final seed = md5
          .convert(utf8.encode('$clusterId|$currentSize'))
          .toString();
      final spots = <TrainingPackSpot>[];
      for (var i = 0; i < currentSize; i++) {
        spots.add(
          TrainingPackSpot(
            id: '${seed}_$i',
            tags: [tags[i % tags.length]],
            board: const ['As'],
          ),
        );
      }
      pack = TrainingPackTemplateV2(
        id: 'assessment_$seed',
        name: 'Assessment',
        trainingType: TrainingType.custom,
        spots: spots,
        spotCount: spots.length,
        tags: tags,
        theme: themeName,
        gameType: GameType.cash,
        meta: {
          'assessment': true,
          'clusterId': clusterId,
          'themeName': themeName,
          'requiredTags': tags,
        },
        isGeneratedPack: true,
      );
      final result = await noveltyGuard.evaluate(pack);
      if (!result.isDuplicate || currentSize <= 1) {
        break;
      }
      currentSize = currentSize - 2;
    }
    return pack!;
  }
}
