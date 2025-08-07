import '../models/v2/training_pack_spot.dart';
import 'mini_lesson_library_service.dart';

/// Automatically links [TrainingPackSpot]s with relevant theory lessons.
///
/// For each spot, the first matching lesson found by tag is written to the
/// [TrainingPackSpot.theoryId] field. Existing values are never overwritten.
/// A summary log is printed indicating how many spots were updated.
class TheoryLinkAutoInjector {
  TheoryLinkAutoInjector({MiniLessonLibraryService? library})
      : _library = library ?? MiniLessonLibraryService.instance;

  final MiniLessonLibraryService _library;

  /// Scans [spots] and injects `theoryId` references when a matching lesson is
  /// found. Only the first matching tag per spot is used.
  Future<void> injectAll(List<TrainingPackSpot> spots) async {
    var injected = 0;
    for (final spot in spots) {
      if (spot.theoryId != null && spot.theoryId!.isNotEmpty) {
        continue;
      }
      for (final tag in spot.tags) {
        final lesson = _library.findLessonByTag(tag);
        if (lesson != null) {
          spot.theoryId = lesson.id;
          injected++;
          break;
        }
      }
    }
    if (injected > 0) {
      // ignore: avoid_print
      print('TheoryLinkAutoInjector: injected $injected links');
    }
  }
}

