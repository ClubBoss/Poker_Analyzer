import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/suggested_weak_tag_pack_service.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/services/training_tag_performance_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  TrainingPackTemplateV2 tpl(
      {required String id, required List<String> tags, double pop = 0}) {
    return TrainingPackTemplateV2(
      id: id,
      name: id,
      trainingType: TrainingType.pushFold,
      tags: tags,
      meta: {'popularity': pop},
    );
  }

  test('returns pack matching weak tag', () async {
    final library = [
      tpl(id: 'a', tags: ['cbet'])
    ];
    final weak = [
      const TagPerformance(
          tag: 'cbet',
          totalAttempts: 0,
          correct: 0,
          accuracy: 0,
          lastTrained: null),
    ];
    final service = SuggestedWeakTagPackService(
      library: library,
      detectWeakTags: () async => weak,
    );
    final result = await service.suggestPack();
    expect(result.isFallback, false);
    expect(result.pack?.id, 'a');
  });

  test('falls back when no matching pack', () async {
    final library = [
      tpl(id: 'b', tags: ['fundamentals']),
      tpl(id: 'c', tags: ['starter'], pop: 5),
    ];
    final service = SuggestedWeakTagPackService(
      library: library,
      detectWeakTags: () async => [],
    );
    final result = await service.suggestPack();
    expect(result.isFallback, true);
    expect(result.pack?.id, 'b');
  });
}
