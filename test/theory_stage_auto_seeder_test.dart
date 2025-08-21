import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/theory_stage_auto_seeder.dart';
import 'package:poker_analyzer/services/learning_path_library.dart';
import 'package:poker_analyzer/services/theory_yaml_importer.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

class _FakeImporter extends TheoryYamlImporter {
  final List<TrainingPackTemplateV2> list;
  const _FakeImporter(this.list);
  @override
  Future<List<TrainingPackTemplateV2>> importFromDirectory(
    String dirPath,
  ) async =>
      list;
}

TrainingPackTemplateV2 _tpl(String id, String tag) => TrainingPackTemplateV2(
      id: id,
      name: id,
      trainingType: TrainingType.theory,
      tags: [tag],
      spots: [TrainingPackSpot(id: 's', type: 'theory', hand: HandData())],
      spotCount: 1,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('seed builds paths grouped by tag', () async {
    final importer = _FakeImporter([
      _tpl('p1', 'pushfold'),
      _tpl('p2', 'pushfold'),
      _tpl('c1', 'call'),
    ]);
    final seeder = TheoryStageAutoSeeder(importer: importer);
    final paths = await seeder.seed();

    expect(paths, hasLength(2));
    final lib = LearningPathLibrary.staging.paths;
    expect(lib, hasLength(2));

    final push = lib.firstWhere((e) => e.id == 'theory_path_pushfold');
    expect(push.stages, hasLength(2));
    expect(push.stages.first.packId, 'p1');
  });
}
