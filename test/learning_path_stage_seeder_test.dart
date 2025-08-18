import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/learning_path_stage_seeder.dart';
import 'package:poker_analyzer/services/learning_path_stage_library.dart';

class _FakeBundle extends CachingAssetBundle {
  final Map<String, String> data;
  _FakeBundle(this.data);
  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      data[key]!;
}

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

    await const LearningPathStageSeeder().seedStages([
      file1.path,
      file2.path,
    ], audience: 'Beginner');

    final stages = LearningPathStageLibrary.instance.stages;
    expect(stages, hasLength(2));
    expect(stages.first.id, 'pack1');
    expect(stages.first.order, 0);
    expect(stages[1].id, 'pack2');
    expect(stages[1].order, 1);
  });

  test('seeds stages from config file', () async {
    final bundle = _FakeBundle({
      'assets/learning_path_tracks.yaml': 'beginner:\n  - assets/p1.yaml',
      'assets/p1.yaml': '''
id: pack1
name: Pack 1
trainingType: mtt
positions:
  - bb
''',
    });
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (
      message,
    ) async {
      final key = utf8.decode(message.buffer.asUint8List());
      final data = bundle.data[key];
      if (data != null) {
        return ByteData.view(Uint8List.fromList(utf8.encode(data)).buffer);
      }
      return null;
    });

    await const LearningPathStageSeeder().seedFromConfig(audience: 'Beginner');

    final stages = LearningPathStageLibrary.instance.stages;
    expect(stages, hasLength(1));
    expect(stages.first.id, 'pack1');
  });
}
