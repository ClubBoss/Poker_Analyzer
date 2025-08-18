import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/controllers/pack_run_controller.dart';
import 'package:poker_analyzer/models/theory_snippet.dart';
import 'package:poker_analyzer/services/theory_index_service.dart';
import 'package:poker_analyzer/models/recall_snippet_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeTheoryIndexService extends TheoryIndexService {
  final TheorySnippet? snippet;
  FakeTheoryIndexService(this.snippet);

  @override
  Future<List<TheorySnippet>> snippetsForTag(String tag) async {
    if (snippet == null) return [];
    return [snippet!];
  }
}

void main() {
  SharedPreferences.setMockInitialValues({});
  test('spot with missing tags -> no card', () async {
    final controller = PackRunController(
      theoryIndex: FakeTheoryIndexService(null),
    );
    final snippet = await controller.onResult('s1', false, []);
    expect(snippet, isNull);
  });

  test('spot with valid tag -> card content matches theory snippet', () async {
    const snippet = TheorySnippet(
      id: 'th_push',
      title: 'Push/Fold Basics',
      bullets: ['Always push'],
    );
    final controller = PackRunController(
      theoryIndex: FakeTheoryIndexService(snippet),
    );
    final RecallSnippetResult? result = await controller.onResult('s1', false, [
      'push',
    ]);
    expect(result?.snippet.id, snippet.id);
    expect(result?.snippet.title, snippet.title);
  });
}
