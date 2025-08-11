import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/controllers/learning_path_controller.dart';
import 'package:poker_analyzer/services/learning_path_loader.dart';
import 'package:poker_analyzer/models/learning_path_template_v2.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';

class _FakeLoader extends LearningPathLoader {
  final LearningPathTemplateV2 tpl;
  const _FakeLoader(this.tpl);
  @override
  Future<LearningPathTemplateV2> load(String pathId) async => tpl;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('completion threshold is inclusive', () async {
    SharedPreferences.setMockInitialValues({});
    final stage = LearningPathStageModel(
      id: 's',
      title: 's',
      description: '',
      packId: 'p',
      requiredAccuracy: 0.7,
      requiredHands: 20,
    );
    final tpl = LearningPathTemplateV2(
      id: 'path',
      title: 'path',
      description: '',
      stages: [stage],
      sections: const [],
      tags: const [],
    );
    final controller = LearningPathController(loader: _FakeLoader(tpl));
    await controller.load('path');
    for (var i = 0; i < 14; i++) {
      controller.recordHand(correct: true);
    }
    for (var i = 0; i < 6; i++) {
      controller.recordHand(correct: false);
    }
    expect(controller.stageProgress('s').completed, true);
  });
}

