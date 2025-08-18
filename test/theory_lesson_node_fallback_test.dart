import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_lesson_node.dart';
import 'package:poker_analyzer/services/theory_content_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await TheoryContentService.instance.reload();
  });

  test('fallback uses shared block when title or content empty', () {
    const node = TheoryLessonNode(
      id: 't1',
      refId: 'welcome',
      title: '',
      content: '',
    );
    expect(node.resolvedTitle, 'Welcome');
    expect(node.resolvedContent, 'Welcome to the Poker Analyzer.');
  });
}
