import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/theory_block_model.dart';
import 'package:poker_analyzer/services/theory_block_review_streak_evaluator.dart';
import 'package:poker_analyzer/services/theory_block_library_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('streak days aggregated and deduped', () async {
    final now = DateTime.now().toUtc();
    SharedPreferences.setMockInitialValues({
      'retention.theoryReviewed.a': now.toIso8601String(),
      'retention.theoryReviewed.b': now.toIso8601String(),
      'retention.theoryReviewed.c':
          now.subtract(const Duration(days: 2)).toIso8601String(),
    });

    final library = _FakeLibrary({
      '1': const TheoryBlockModel(
        id: '1',
        title: 'b1',
        nodeIds: [],
        practicePackIds: [],
        tags: ['a', 'b'],
      ),
      '2': const TheoryBlockModel(
        id: '2',
        title: 'b2',
        nodeIds: [],
        practicePackIds: [],
        tags: ['c'],
      ),
    });

    final evaluator = TheoryBlockReviewStreakEvaluator(library: library);
    final days = await evaluator.getStreakDays();
    final today = DateTime.utc(now.year, now.month, now.day);
    final twoAgo = today.subtract(const Duration(days: 2));
    expect(days, [twoAgo, today]);
  });

  test('current and max streak computed', () async {
    final now = DateTime.now().toUtc();
    SharedPreferences.setMockInitialValues({
      'retention.theoryReviewed.t1': now.toIso8601String(),
      'retention.theoryReviewed.t2':
          now.subtract(const Duration(days: 1)).toIso8601String(),
      'retention.theoryReviewed.t3':
          now.subtract(const Duration(days: 3)).toIso8601String(),
    });

    final library = _FakeLibrary({
      'b': const TheoryBlockModel(
        id: 'b',
        title: 'b',
        nodeIds: [],
        practicePackIds: [],
        tags: ['t1', 't2', 't3'],
      ),
    });

    final evaluator = TheoryBlockReviewStreakEvaluator(library: library);
    expect(await evaluator.getCurrentStreak(), 2);
    expect(await evaluator.getMaxStreak(), 2);
  });
}

class _FakeLibrary implements TheoryBlockLibraryService {
  _FakeLibrary(this._map);
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
