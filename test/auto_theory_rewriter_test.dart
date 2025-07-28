import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/auto_theory_rewriter.dart';
import 'package:poker_analyzer/services/mini_lesson_library_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rewrite formats lesson content and extracts examples', () {
    const entry = MiniLessonEntry(
      tag: 'aggression',
      title: 'Aggression basics',
      content: 'Aggression wins pots. Example: aggression forces folds.',
    );

    final rewritten = const AutoTheoryRewriter().rewrite([entry]);
    expect(rewritten.length, 1);
    final r = rewritten.first;
    expect(r.title, contains('**aggression**'));
    expect(r.content.startsWith('- '), isTrue);
    expect(r.examples, isNotEmpty);
  });
}
