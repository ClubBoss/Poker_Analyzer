import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/learning_path_booster_engine.dart';
import 'package:poker_analyzer/services/tag_mastery_service.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';

class _FakeMasteryService extends TagMasteryService {
  final Map<String, double> _map;
  _FakeMasteryService(this._map)
    : super(logs: SessionLogService(sessions: TrainingSessionService()));

  @override
  Future<Map<String, double>> computeMastery({bool force = false}) async =>
      _map;
}

TrainingPackTemplateV2 tpl({
  required String id,
  required List<String> tags,
  double score = 1.0,
}) {
  return TrainingPackTemplateV2(
    id: id,
    name: id,
    trainingType: TrainingType.pushFold,
    tags: tags,
    meta: {'rankScore': score},
    spots: const [],
    spotCount: 0,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns packs sorted by weakness priority', () async {
    final library = [
      tpl(id: 'a', tags: ['cbet'], score: 0.5),
      tpl(id: 'b', tags: ['cbet'], score: 0.9),
      tpl(id: 'c', tags: ['icm'], score: 1.0),
    ];
    final mastery = _FakeMasteryService({'cbet': 0.2, 'icm': 0.8});
    final engine = LearningPathBoosterEngine(library: library);
    final result = await engine.getBoosterPacks(mastery: mastery, maxPacks: 2);
    expect(result.map((e) => e.id).toList(), ['b', 'a']);
  });
}
