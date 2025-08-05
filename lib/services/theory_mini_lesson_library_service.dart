import '../models/theory_mini_lesson_node.dart';
import 'theory_pack_importer_service.dart';

/// Simple in-memory library for [TheoryMiniLessonNode] used by CLI tools.
class TheoryMiniLessonLibraryService {
  TheoryMiniLessonLibraryService._();

  /// Singleton instance.
  static final TheoryMiniLessonLibraryService instance =
      TheoryMiniLessonLibraryService._();

  final List<TheoryMiniLessonNode> _lessons = [];

  /// Unmodifiable list of loaded lessons.
  List<TheoryMiniLessonNode> get lessons => List.unmodifiable(_lessons);

  /// Loads lessons from [dirs] using [TheoryPackImporterService].
  Future<void> loadFromDirs(List<String> dirs) async {
    _lessons.clear();
    final importer = const TheoryPackImporterService();
    for (final dir in dirs) {
      final list = await importer.importLessons(dir);
      _lessons.addAll(list);
    }
  }

  /// Adds [lessons] to the library.
  void register(List<TheoryMiniLessonNode> lessons) {
    _lessons.addAll(lessons);
  }
}

