import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/learning_path_template_v2.dart';
import 'package:poker_analyzer/services/learning_path_unlock_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final engine = LearningPathUnlockEngine.instance;

  LearningPathTemplateV2 path0({List<String>? prereq}) =>
      LearningPathTemplateV2(
        id: 'p',
        title: 'Path',
        description: '',
        prerequisitePathIds: prereq,
      );

  test('unlocked when no prerequisites', () {
    final path = path0();
    final ok = engine.isPathUnlocked(path, {'a'});
    expect(ok, isTrue);
  });

  test('unlocked when all prerequisites completed', () {
    final path = path0(prereq: ['a', 'b']);
    final ok = engine.isPathUnlocked(path, {'a', 'b', 'x'});
    expect(ok, isTrue);
  });

  test('locked when any prerequisite missing', () {
    final path = path0(prereq: ['a', 'b']);
    final ok = engine.isPathUnlocked(path, {'a'});
    expect(ok, isFalse);
  });
}
