import 'mini_lesson_progress_tracker.dart';
import 'pack_library_completion_service.dart';

/// Provides completion lookups for theory lessons and training packs.
class UserProgressService {
  UserProgressService._();
  static final instance = UserProgressService._();

  Future<bool> isTheoryLessonCompleted(String id) {
    return MiniLessonProgressTracker.instance.isCompleted(id);
  }

  Future<bool> isPackCompleted(String id) async {
    final data = await PackLibraryCompletionService.instance.getCompletion(id);
    return data != null;
  }
}
