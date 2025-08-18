import 'dart:async';

import 'mini_lesson_library_service.dart';
import 'mini_lesson_progress_tracker.dart';

/// Holds summary of theory lesson progress.
class TheoryLessonProgressState {
  final int completed;
  final int total;
  const TheoryLessonProgressState({
    required this.completed,
    required this.total,
  });
}

/// Provides reactive updates for overall theory lesson progress.
class TheoryLessonProgressTrackerService {
  TheoryLessonProgressTrackerService._({
    MiniLessonLibraryService? library,
    MiniLessonProgressTracker? progress,
  }) : _library = library ?? MiniLessonLibraryService.instance,
       _progress = progress ?? MiniLessonProgressTracker.instance {
    _progress.onLessonCompleted.listen((_) => refresh());
    refresh();
  }

  static final TheoryLessonProgressTrackerService instance =
      TheoryLessonProgressTrackerService._();

  final MiniLessonLibraryService _library;
  final MiniLessonProgressTracker _progress;
  final _controller = StreamController<TheoryLessonProgressState>.broadcast();
  TheoryLessonProgressState _state = const TheoryLessonProgressState(
    completed: 0,
    total: 0,
  );

  /// Current progress state.
  TheoryLessonProgressState get current => _state;

  /// Stream of progress state updates.
  Stream<TheoryLessonProgressState> get stream => _controller.stream;

  /// Refreshes progress counts and emits a new state if changed.
  Future<void> refresh() async {
    final total = await _library.getTotalLessonCount();
    final completed = await _library.getCompletedLessonCount();
    final next = TheoryLessonProgressState(completed: completed, total: total);
    if (next.completed != _state.completed || next.total != _state.total) {
      _state = next;
      _controller.add(_state);
    }
  }

  /// Forces listeners to receive the current progress state.
  Future<void> forceRefresh() async {
    await refresh();
    _controller.add(_state);
  }
}
