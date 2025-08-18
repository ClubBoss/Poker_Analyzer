import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/controllers/pack_run_controller.dart';
import 'package:poker_analyzer/models/pack_run_session_state.dart';
import 'package:poker_analyzer/models/recall_snippet_result.dart';
import 'package:poker_analyzer/models/theory_snippet.dart';
import 'package:poker_analyzer/services/theory_index_service.dart';

class _FakeTheoryIndexService extends TheoryIndexService {
  final Map<String, List<TheorySnippet>> data;
  _FakeTheoryIndexService(this.data);

  @override
  Future<List<TheorySnippet>> snippetsForTag(String tag) async =>
      data[tag] ?? [];
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('tag cooldown is respected', () async {
    final service = _FakeTheoryIndexService({
      't': [const TheorySnippet(id: '1', title: 't', bullets: [])],
    });
    final state = PackRunSessionState(scopeKey: 'k1');
    final controller = PackRunController(theoryIndex: service, state: state);

    final first = await controller.onResult('s1', false, ['t']);
    expect(first, isA<RecallSnippetResult>());

    final second = await controller.onResult('s2', false, ['t']);
    expect(second, isNull);

    for (var i = 0; i < 8; i++) {
      await controller.onResult('sx$i', true, []);
    }

    final third = await controller.onResult('s11', false, ['t']);
    expect(third, isA<RecallSnippetResult>());
  });

  test('rotation without repeats', () async {
    final service = _FakeTheoryIndexService({
      't': [
        const TheorySnippet(id: '1', title: 'a', bullets: []),
        const TheorySnippet(id: '2', title: 'b', bullets: []),
        const TheorySnippet(id: '3', title: 'c', bullets: []),
      ],
    });
    final state = PackRunSessionState(scopeKey: 'k2');
    final controller = PackRunController(theoryIndex: service, state: state);

    final seen = <String>[];
    for (var i = 0; i < 3; i++) {
      final res = await controller.onResult('s$i', false, ['t']);
      seen.add(res!.snippet.id);
      for (var j = 0; j < 10; j++) {
        await controller.onResult('c$i$j', true, []);
      }
    }
    expect(seen, ['1', '2', '3']);

    final next = await controller.onResult('s-last', false, ['t']);
    expect(next!.snippet.id, '1');
  });

  test('persistence round-trip', () async {
    final state = PackRunSessionState(
      scopeKey: 'k3',
      handCounter: 5,
      lastShownAt: 2,
      tagLastShown: {'a': 1},
      recallHistory: {
        'a': ['1'],
      },
      recallShownBySpot: {'s1': true},
      attemptsBySpot: {'s1': 2},
    );
    await state.save();

    final loaded = await PackRunSessionState.load('k3');
    expect(loaded.handCounter, 5);
    expect(loaded.tagLastShown['a'], 1);
    expect(loaded.recallHistory['a'], ['1']);
    expect(loaded.recallShownBySpot['s1'], isTrue);
    expect(loaded.attemptsBySpot['s1'], 2);
  });

  test('global cooldown prevents other tags', () async {
    final service = _FakeTheoryIndexService({
      'a': [const TheorySnippet(id: '1', title: 'a', bullets: [])],
      'b': [const TheorySnippet(id: '2', title: 'b', bullets: [])],
    });
    final state = PackRunSessionState(scopeKey: 'k4');
    final controller = PackRunController(theoryIndex: service, state: state);

    final first = await controller.onResult('s1', false, ['a']);
    expect(first, isNotNull);

    final blocked = await controller.onResult('s2', false, ['b']);
    expect(blocked, isNull);

    await controller.onResult('s3', true, []);
    final shown = await controller.onResult('s4', false, ['b']);
    expect(shown!.tagId, 'b');
  });
}
