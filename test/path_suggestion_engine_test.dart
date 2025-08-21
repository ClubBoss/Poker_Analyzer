import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/learning_path_template_v2.dart';
import 'package:poker_analyzer/services/path_suggestion_engine.dart';

class _Path extends LearningPathTemplateV2 {
  final Map<String, dynamic> meta;
  final bool recommendedFlag;

  _Path({required String id, List<String>? tags, this.meta = const {}})
      : super(id: id, title: id, description: '', tags: tags);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #meta) return meta;
    if (invocation.memberName == #recommended) return recommendedFlag;
    return super.noSuchMethod(invocation);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const engine = PathSuggestionEngine();

  test('returns null when all paths completed', () async {
    final paths = [_Path(id: 'a'), _Path(id: 'b')];
    final result = await engine.suggestNextPath(
      allPaths: paths,
      completedPathIds: {'a', 'b'},
    );
    expect(result, isNull);
  });

  test('prefers recommended or starter paths', () async {
    final a = _Path(id: 'a');
    final b = _Path(id: 'b', tags: ['starter']);
    final result = await engine.suggestNextPath(
      allPaths: [a, b],
      completedPathIds: {},
    );
    expect(result, b);
  });

  test('sorts by order when available', () async {
    final a = _Path(id: 'a', meta: {'order': 2});
    final b = _Path(id: 'b', meta: {'order': 1});
    final result = await engine.suggestNextPath(
      allPaths: [a, b],
      completedPathIds: {},
    );
    expect(result, b);
  });

  test('sorts by difficulty then createdAt', () async {
    final older = DateTime(2020, 1, 1).toIso8601String();
    final newer = DateTime(2021, 1, 1).toIso8601String();
    final a = _Path(id: 'a', meta: {'difficultyLevel': 2, 'createdAt': older});
    final b = _Path(id: 'b', meta: {'difficultyLevel': 1, 'createdAt': newer});
    final result = await engine.suggestNextPath(
      allPaths: [a, b],
      completedPathIds: {},
    );
    expect(result, b);
  });
}
