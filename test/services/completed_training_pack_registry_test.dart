import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
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

  test('store and retrieve completed pack data', () async {
    final registry = CompletedTrainingPackRegistry();
    final pack = buildPack('p1');
    final completedAt = DateTime.utc(2024, 1, 1);
    await registry.storeCompletedPack(
      pack,
      completedAt: completedAt,
      accuracy: 0.85,
    );

    final fp = const TrainingPackFingerprintGenerator().generate(pack);
    final data = await registry.getCompletedPackData(fp);
    expect(data, isNotNull);
    expect(data!['yaml'], equals(pack.toYamlString()));
    expect(DateTime.parse(data['timestamp'] as String), completedAt);
    expect(data['type'], equals('quiz'));
    expect((data['accuracy'] as num).toDouble(), closeTo(0.85, 1e-9));

    final all = await registry.listCompletedFingerprints();
    expect(all, contains(fp));
  });
}
