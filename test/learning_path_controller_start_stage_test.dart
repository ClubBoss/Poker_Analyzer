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

  test('startStage sets currentStageId and startedAt', () async {
    SharedPreferences.setMockInitialValues({});
    final stage = LearningPathStageModel(
      id: 's',
      title: 's',
      description: '',
      packId: 'p',
      requiredAccuracy: 0.5,
      requiredHands: 1,
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
    controller.startStage('s');
    expect(controller.currentStageId, 's');
    expect(controller.stageProgress('s').startedAt, isNotNull);
  });
}
