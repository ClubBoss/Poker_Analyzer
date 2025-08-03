import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/theory_block_model.dart';
import 'package:poker_analyzer/services/pinned_block_tracker_service.dart';
import 'package:poker_analyzer/services/smart_pinned_block_booster_provider.dart';
import 'package:poker_analyzer/services/theory_block_library_service.dart';
import 'package:poker_analyzer/services/decay_recall_evaluator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('suggests boosters for pinned blocks with decayed tags', () async {
    final tracker = PinnedBlockTrackerService.instance;
    await tracker.logPin('b1');
    await tracker.logPin('b2');

    const block1 = TheoryBlockModel(
      id: 'b1',
      title: 'Block 1',
      nodeIds: [],
      practicePackIds: ['p1'],
      tags: ['t1'],
    );

    const block2 = TheoryBlockModel(
      id: 'b2',
      title: 'Block 2',
      nodeIds: [],
      practicePackIds: [],
      tags: ['t2'],
    );

    final library = _FakeBlockLibrary({block1.id: block1, block2.id: block2});
    final evaluator = _FakeEvaluator({'b1': ['t1'], 'b2': ['t2']});

    final provider = SmartPinnedBlockBoosterProvider(
      tracker: tracker,
      library: library,
      evaluator: evaluator,
    );

    final boosters = await provider.getBoosters();
    expect(boosters.length, 2);
    final first = boosters.firstWhere((b) => b.blockId == 'b1');
    expect(first.tag, 't1');
    expect(first.action, 'resumePack');
    expect(first.packId, 'p1');

    final second = boosters.firstWhere((b) => b.blockId == 'b2');
    expect(second.tag, 't2');
    expect(second.action, 'reviewTheory');
    expect(second.packId, isNull);
  });
}

class _FakeBlockLibrary implements TheoryBlockLibraryService {
  _FakeBlockLibrary(this._map);
  final Map<String, TheoryBlockModel> _map;

  @override
  List<TheoryBlockModel> get all => _map.values.toList();

  @override
  TheoryBlockModel? getById(String id) => _map[id];

  @override
  Future<void> loadAll() async {}

  @override
  Future<void> reload() async {}
}

class _FakeEvaluator extends DecayRecallEvaluatorService {
  final Map<String, List<String>> _map;
  const _FakeEvaluator(this._map);

  @override
  Future<List<String>> getDecayedTags(TheoryBlockModel block,
      {double threshold = 30}) async {
    return _map[block.id] ?? [];
  }

  @override
  Future<bool> hasDecayedTags(TheoryBlockModel block,
      {double threshold = 30}) async {
    return (await getDecayedTags(block, threshold: threshold)).isNotEmpty;
  }
}
