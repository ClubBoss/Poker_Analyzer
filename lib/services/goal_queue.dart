import '../models/theory_mini_lesson_node.dart';

class GoalQueue {
  GoalQueue._();
  static final GoalQueue instance = GoalQueue._();

  final List<TheoryMiniLessonNode> _items = [];

  void push(TheoryMiniLessonNode lesson) {
    _items.add(lesson);
  }

  void remove(String lessonId) {
    _items.removeWhere((e) => e.id == lessonId);
  }

  List<TheoryMiniLessonNode> getQueue() => List.unmodifiable(_items);

  void clear() => _items.clear();
}
