import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/learning_path_template_v2.dart';
import 'package:poker_analyzer/services/learning_path_orchestrator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resolve builds starter path when cache empty', () async {
    SharedPreferences.setMockInitialValues({});
    final orch = LearningPathOrchestrator.instance;
    final path = await orch.resolve();
    expect(path.id.isNotEmpty, true);
  });

  test('resolve loads cached path', () async {
    const tpl = LearningPathTemplateV2(
      id: 'cached',
      title: 'cached',
      description: '',
    );
    SharedPreferences.setMockInitialValues({
      'current_learning_path_v2': jsonEncode(tpl.toJson()),
    });
    final orch = LearningPathOrchestrator.instance;
    final path = await orch.resolve();
    expect(path.id, 'cached');
  });
}
