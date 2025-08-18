import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/learning_path_config_loader.dart';
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

  test('loadPath registers stages from packs', () async {
    final bundle = _FakeBundle({
      'assets/learning_paths/beginner_path.yaml':
          'packs:\n  - assets/p1.yaml\n  - assets/p2.yaml',
      'assets/p1.yaml':
          'id: pack1\nname: Pack 1\ntrainingType: mtt\npositions:\n  - bb',
      'assets/p2.yaml':
          'id: pack2\nname: Pack 2\ntrainingType: mtt\npositions:\n  - bb',
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

    LearningPathStageLibrary.instance.clear();

    await LearningPathConfigLoader.instance.loadPath(
      'assets/learning_paths/beginner_path.yaml',
    );

    final stages = LearningPathStageLibrary.instance.stages;
    expect(stages, hasLength(2));
    expect(stages.first.id, 'pack1');
    expect(stages.first.order, 0);
    expect(stages[1].id, 'pack2');
    expect(stages[1].order, 1);
  });
}
