import '../models/v2/training_pack_spot.dart';
import '../models/autogen_status.dart';
import 'mini_lesson_library_service.dart';
import 'autogen_status_dashboard_service.dart';

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
    final status = AutogenStatusDashboardService.instance;
    status.update(
      'TheoryLinkAutoInjector',
      const AutogenStatus(
        isRunning: true,
        currentStage: 'inject',
        progress: 0,
      ),
    );
    try {
      var injected = 0;
      for (var i = 0; i < spots.length; i++) {
        final spot = spots[i];
        if (spot.theoryId != null && spot.theoryId!.isNotEmpty) {
          status.update(
            'TheoryLinkAutoInjector',
            AutogenStatus(
              isRunning: true,
              currentStage: 'inject',
              progress: (i + 1) / spots.length,
            ),
          );
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
        status.update(
          'TheoryLinkAutoInjector',
          AutogenStatus(
            isRunning: true,
            currentStage: 'inject',
            progress: (i + 1) / spots.length,
          ),
        );
      }
      if (injected > 0) {
        // ignore: avoid_print
        print('TheoryLinkAutoInjector: injected $injected links');
      }
      status.update(
        'TheoryLinkAutoInjector',
        const AutogenStatus(
          isRunning: false,
          currentStage: 'complete',
          progress: 1,
        ),
      );
    } catch (e) {
      status.update(
        'TheoryLinkAutoInjector',
        AutogenStatus(
          isRunning: false,
          currentStage: 'error',
          progress: 0,
          lastError: e.toString(),
        ),
      );
      rethrow;
    }
  }
}

