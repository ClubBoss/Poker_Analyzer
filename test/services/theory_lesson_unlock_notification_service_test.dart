import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/theory_lesson_unlock_notification_service.dart';

class _FakeLibrary implements MiniLessonLibraryService {
  final Map<String, TheoryMiniLessonNode> items;
  _FakeLibrary(this.items);

  @override
  List<TheoryMiniLessonNode> get all => items.values.toList();

  @override
  TheoryMiniLessonNode? getById(String id) => items[id];

  @override
  Future<void> loadAll() async {}

  @override
  Future<void> reload() async {}

  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) => const [];

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows snackbar for newly unlocked lessons', (tester) async {
    SharedPreferences.setMockInitialValues({
      TheoryLessonUnlockNotificationService.storageKey: ['a'],
    });
    final library = _FakeLibrary({
      'a': const TheoryMiniLessonNode(id: 'a', title: 'A', content: ''),
      'b': const TheoryMiniLessonNode(id: 'b', title: 'B', content: ''),
    });
    final service = TheoryLessonUnlockNotificationService(library: library);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: Container(key: key))),
    );
    final ctx = key.currentContext!;
    await service.checkAndNotify(['a', 'b'], ctx);
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text('New lesson unlocked: B\n(0 of 2 lessons complete)'),
      findsOneWidget,
    );
    expect(find.text('View'), findsOneWidget);
  });

  testWidgets('does nothing when no new lessons', (tester) async {
    SharedPreferences.setMockInitialValues({
      TheoryLessonUnlockNotificationService.storageKey: ['a'],
    });
    final library = _FakeLibrary({
      'a': const TheoryMiniLessonNode(id: 'a', title: 'A', content: ''),
    });
    final service = TheoryLessonUnlockNotificationService(library: library);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: Container(key: key))),
    );
    final ctx = key.currentContext!;
    await service.checkAndNotify(['a'], ctx);
    await tester.pump();
    expect(find.byType(SnackBar), findsNothing);
  });
}
