import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/lesson_step_tag_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('getTagsByStepId returns tags for steps with tags', () async {
    final tags = await LessonStepTagService.instance.getTagsByStepId();
    expect(tags.containsKey('lesson1'), true);
    expect(tags['lesson1'], ['BTN', 'push']);
    expect(tags.containsKey('lesson2'), false);
  });
}
