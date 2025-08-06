import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/services/completed_session_summary_service.dart';
import 'package:poker_analyzer/services/completed_training_pack_registry.dart';
import 'package:poker_analyzer/services/training_pack_fingerprint_generator.dart';
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

  test('load summaries sorted by timestamp', () async {
    final registry = CompletedTrainingPackRegistry();
    final pack1 = buildPack('p1');
    final pack2 = buildPack('p2');
    final time1 = DateTime.utc(2024, 1, 1);
    final time2 = DateTime.utc(2024, 2, 1);

    await registry.storeCompletedPack(pack1, completedAt: time1, accuracy: 0.8);
    await registry.storeCompletedPack(pack2, completedAt: time2, accuracy: 0.9);

    final service = CompletedSessionSummaryService(registry: registry);
    final summaries = await service.loadSummaries();

    expect(summaries, hasLength(2));
    final fp1 = const TrainingPackFingerprintGenerator().generateFromTemplate(
      pack1,
    );
    final fp2 = const TrainingPackFingerprintGenerator().generateFromTemplate(
      pack2,
    );

    expect(summaries[0].fingerprint, fp2);
    expect(summaries[0].timestamp, time2);
    expect(summaries[0].trainingType, 'quiz');
    expect(summaries[0].accuracy, closeTo(0.9, 1e-9));
    expect(summaries[0].yaml, pack2.toYamlString());

    expect(summaries[1].fingerprint, fp1);
    expect(summaries[1].timestamp, time1);
    expect(summaries[1].trainingType, 'quiz');
    expect(summaries[1].accuracy, closeTo(0.8, 1e-9));
    expect(summaries[1].yaml, pack1.toYamlString());
  });
}
