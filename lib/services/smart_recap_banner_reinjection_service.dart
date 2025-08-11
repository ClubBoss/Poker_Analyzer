import 'dart:async';


import 'mini_lesson_library_service.dart';
import 'recap_auto_repeat_scheduler.dart';
import 'smart_recap_banner_controller.dart';
import 'recap_fatigue_evaluator.dart';
import 'theory_recap_suppression_engine.dart';
import 'smart_theory_recap_dismissal_memory.dart';
import 'theory_injection_horizon_service.dart';

/// Listens for due recap lessons and reinserts them into the banner flow.
class SmartRecapBannerReinjectionService {
  final RecapAutoRepeatScheduler scheduler;
  final MiniLessonLibraryService library;
  final SmartRecapBannerController controller;
  final RecapFatigueEvaluator fatigue;
  final TheoryRecapSuppressionEngine suppression;
  final SmartTheoryRecapDismissalMemory dismissal;

  SmartRecapBannerReinjectionService({
    RecapAutoRepeatScheduler? scheduler,
    MiniLessonLibraryService? library,
    required this.controller,
    RecapFatigueEvaluator? fatigue,
    TheoryRecapSuppressionEngine? suppression,
    SmartTheoryRecapDismissalMemory? dismissal,
  }) : scheduler = scheduler ?? RecapAutoRepeatScheduler.instance,
       library = library ?? MiniLessonLibraryService.instance,
       fatigue = fatigue ?? RecapFatigueEvaluator.instance,
       suppression = suppression ?? TheoryRecapSuppressionEngine.instance,
       dismissal = dismissal ?? SmartTheoryRecapDismissalMemory.instance;

  StreamSubscription<List<String>>? _sub;

  /// Starts listening for pending recap ids.
  Future<void> start({Duration interval = const Duration(hours: 1)}) async {
    await library.loadAll();
    _sub?.cancel();
    _sub = scheduler.getPendingRecapIds(interval: interval).listen(_handleIds);
  }

  /// Disposes the service and cancels listeners.
  Future<void> dispose() async {
    await _sub?.cancel();
  }

  Future<void> _handleIds(List<String> ids) async {
    for (final id in ids) {
      final lesson = library.getById(id);
      if (lesson == null) continue;
      if (controller.shouldShowBanner() &&
          controller.getPendingLesson()?.id == lesson.id) {
        continue;
      }
      if (await fatigue.isFatigued(lesson.id)) continue;
      if (await suppression.shouldSuppress(
        lessonId: lesson.id,
        trigger: 'reinjection',
      )) {
        continue;
      }
      if (await dismissal.shouldThrottle('lesson:${lesson.id}')) continue;
      if (!await TheoryInjectionHorizonService.instance.canInject('recap')) {
        continue;
      }
      await controller.showManually(lesson);
      await TheoryInjectionHorizonService.instance.markInjected('recap');
    }
  }
}
