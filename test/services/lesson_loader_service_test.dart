import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/lesson_loader_service.dart';

void main() {
  test('loadAllLessons loads lesson steps from assets', () async {
    final lessons = await LessonLoaderService.instance.loadAllLessons();
    expect(lessons, isNotEmpty);
    final first = lessons.first;
    expect(first.id, isNotEmpty);
  });
}
