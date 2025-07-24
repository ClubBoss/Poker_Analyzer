import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/learning_path_stage_seeder.dart';
import 'package:poker_analyzer/services/learning_path_stage_library.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('seeds stages from YAML files', () async {
    final dir = await Directory.systemTemp.createTemp('seeder_test');
    final file1 = File('${dir.path}/p1.yaml');
    final file2 = File('${dir.path}/p2.yaml');

    file1.writeAsStringSync('''
id: pack1
name: Pack 1
trainingType: mtt
positions:
  - bb
''');

    file2.writeAsStringSync('''
id: pack2
name: Pack 2
trainingType: mtt
positions:
  - bb
''');

    await const LearningPathStageSeeder().seedStages(
      [file1.path, file2.path],
      audience: 'Beginner',
    );

    final stages = LearningPathStageLibrary.instance.stages;
    expect(stages, hasLength(2));
    expect(stages.first.id, 'pack1');
    expect(stages.first.order, 0);
    expect(stages[1].id, 'pack2');
    expect(stages[1].order, 1);
  });
}
