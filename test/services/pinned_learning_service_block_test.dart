import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/pinned_learning_service.dart';
import 'package:poker_analyzer/models/theory_block_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PinnedLearningService block', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await PinnedLearningService.instance.load();
    });

    test('toggleBlock pins block and removes child pins', () async {
      final svc = PinnedLearningService.instance;
      await svc.toggle('lesson', 'l1');
      expect(svc.items.length, 1);
      const block = TheoryBlockModel(
        id: 'b',
        title: 'B',
        nodeIds: ['l1'],
        practicePackIds: ['p1'],
      );
      await svc.toggleBlock(block);
      expect(svc.items.length, 1);
      expect(svc.items.first.type, 'block');
      expect(svc.isPinned('lesson', 'l1'), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('pinned_block_b'), isTrue);
    });

    test('pinning lesson removes parent block', () async {
      final svc = PinnedLearningService.instance;
      const block = TheoryBlockModel(
        id: 'b',
        title: 'B',
        nodeIds: ['l1'],
        practicePackIds: [],
      );
      await svc.toggleBlock(block);
      expect(svc.items.any((e) => e.type == 'block'), isTrue);
      await svc.toggle('lesson', 'l1');
      expect(svc.items.any((e) => e.type == 'block'), isFalse);
      expect(svc.items.any((e) => e.type == 'lesson'), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('pinned_block_b'), isNull);
    });
  });
}
