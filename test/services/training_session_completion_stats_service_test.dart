import 'dart:convert';

import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/services/completed_training_pack_registry.dart';
import 'package:poker_analyzer/services/training_pack_fingerprint_generator.dart';
import 'package:poker_analyzer/services/training_session_completion_stats_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  TrainingPackTemplateV2 buildPack(String id) {
    return TrainingPackTemplateV2(
      id: id,
      name: 'Pack $id',
      trainingType: TrainingType.quiz,
      spots: [TrainingPackSpot(id: 's1', hand: HandData())],
      spotCount: 1,
    );
  }

  test('computes aggregate stats for completed sessions', () async {
    final registry = CompletedTrainingPackRegistry();
    final pack1 = buildPack('p1');
    final pack2 = buildPack('p2');

    await registry.storeCompletedPack(pack1, accuracy: 0.8);
    await registry.storeCompletedPack(pack2, accuracy: 0.6);

    // Inject durations into stored data.
    final fp1 = const TrainingPackFingerprintGenerator().generate(pack1);
    final fp2 = const TrainingPackFingerprintGenerator().generate(pack2);
    final prefs = await SharedPreferences.getInstance();
    final data1 = jsonDecode(prefs.getString('completed_pack_$fp1')!) as Map;
    data1['durationMs'] = 60000;
    await prefs.setString('completed_pack_$fp1', jsonEncode(data1));
    final data2 = jsonDecode(prefs.getString('completed_pack_$fp2')!) as Map;
    data2['durationMs'] = 120000;
    await prefs.setString('completed_pack_$fp2', jsonEncode(data2));

    final service =
        TrainingSessionCompletionStatsService(registry: registry);
    final stats = await service.computeStats();

    expect(stats.totalSessions, 2);
    expect(stats.averageAccuracy, closeTo(0.7, 1e-9));
    expect(stats.averageDuration, const Duration(minutes: 1, seconds: 30));
  });
}
