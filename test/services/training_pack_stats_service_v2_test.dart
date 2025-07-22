import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/training_pack_stats_service_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/models/game_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TrainingPackTemplateV2 tpl({required String id, required Map<String, dynamic> meta}) {
    return TrainingPackTemplateV2(
      id: id,
      name: id,
      trainingType: TrainingType.pushFold,
      tags: const [],
      spots: const [],
      spotCount: 10,
      created: DateTime.now(),
      gameType: GameType.tournament,
      positions: const [],
      meta: meta,
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('records pack results and computes improvement per tag', () async {
    final pack = tpl(id: 'p1', meta: {'tag': 'cbet', 'type': 'booster'});
    await TrainingPackStatsServiceV2.recordPackResult(pack, 0.5, -0.2, now: DateTime(2024, 1, 1));
    await TrainingPackStatsServiceV2.recordPackResult(pack, 0.9, -0.1, now: DateTime(2024, 1, 2));
    final map = await TrainingPackStatsServiceV2.improvementByTag();
    expect(map['cbet']!, closeTo(0.4, 0.0001));
  });
});
