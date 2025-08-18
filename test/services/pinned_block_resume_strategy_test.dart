import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/theory_block_model.dart';
import 'package:poker_analyzer/models/resume_target.dart';
import 'package:poker_analyzer/services/pinned_block_resume_strategy.dart';
import 'package:poker_analyzer/services/pinned_block_tracker_service.dart';
import 'package:poker_analyzer/services/smart_resume_engine.dart';
import 'package:poker_analyzer/services/theory_block_library_service.dart';
import 'package:poker_analyzer/services/theory_path_completion_evaluator_service.dart';
import 'package:poker_analyzer/services/user_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('returns most recent pinned incomplete block', () async {
    final tracker = PinnedBlockTrackerService.instance;
    await tracker.logPin('a');
    await Future.delayed(const Duration(milliseconds: 1));
    await tracker.logPin('b');
    await Future.delayed(const Duration(milliseconds: 1));
    await tracker.logPin('c');

    final blocks = {
      'a': const TheoryBlockModel(
        id: 'a',
        title: 'A',
        nodeIds: [],
        practicePackIds: [],
      ),
      'b': const TheoryBlockModel(
        id: 'b',
        title: 'B',
        nodeIds: [],
        practicePackIds: [],
      ),
      'c': const TheoryBlockModel(
        id: 'c',
        title: 'C',
        nodeIds: [],
        practicePackIds: [],
      ),
    };

    final library = _FakeBlockLibrary(blocks);
    final evaluator = _FakeEvaluator({'b': true}); // mark b completed

    final strategy = PinnedBlockResumeStrategy(
      tracker: tracker,
      library: library,
      evaluator: evaluator,
    );

    final engine = SmartResumeEngine(strategies: [strategy]);

    final target = await engine.getResumeTarget();
    expect(target, isNotNull);
    expect(target!.id, 'c');
    expect(target.type, ResumeType.block);
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

class _FakeEvaluator extends TheoryPathCompletionEvaluatorService {
  _FakeEvaluator(this._completed) : super(userProgress: _FakeProgressService());
  final Map<String, bool> _completed;

  @override
  Future<bool> isBlockCompleted(TheoryBlockModel block) async {
    return _completed[block.id] ?? false;
  }
}

class _FakeProgressService implements UserProgressService {
  @override
  Future<bool> isPackCompleted(String id) async => false;

  @override
  Future<bool> isTheoryLessonCompleted(String id) async => false;
}
