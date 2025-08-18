import 'dart:async';

import 'recall_analytics_service.dart';
import 'theory_reinforcement_scheduler.dart';
import 'theory_replay_cooldown_manager.dart';
import 'theory_reinforcement_queue_service.dart';

class TheoryCompletionEvent {
  final String lessonId;
  final bool wasSuccessful;
  final DateTime timestamp;

  TheoryCompletionEvent({
    required this.lessonId,
    required this.wasSuccessful,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class TheoryCompletionEventDispatcher {
  TheoryCompletionEventDispatcher._() {
    addListener((event) {
      unawaited(TheoryReplayCooldownManager.markSuggested(event.lessonId));
    });
    addListener((event) {
      if (event.wasSuccessful) {
        unawaited(
          TheoryReinforcementScheduler.instance.registerSuccess(event.lessonId),
        );
      } else {
        unawaited(
          TheoryReinforcementScheduler.instance.registerFailure(event.lessonId),
        );
      }
    });
    addListener((event) {
      if (event.wasSuccessful) {
        unawaited(
          TheoryReinforcementQueueService.instance.registerSuccess(
            event.lessonId,
          ),
        );
      } else {
        unawaited(
          TheoryReinforcementQueueService.instance.registerFailure(
            event.lessonId,
          ),
        );
      }
    });
    addListener((event) {
      RecallAnalyticsService.instance.logPrompt(
        trigger: 'theoryCompletion',
        lessonId: event.lessonId,
        dismissed: false,
      );
    });
  }

  static final TheoryCompletionEventDispatcher instance =
      TheoryCompletionEventDispatcher._();

  final List<void Function(TheoryCompletionEvent)> _listeners = [];

  void addListener(void Function(TheoryCompletionEvent) fn) {
    _listeners.add(fn);
  }

  void removeListener(void Function(TheoryCompletionEvent) fn) {
    _listeners.remove(fn);
  }

  void dispatch(TheoryCompletionEvent event) {
    for (final l in List<void Function(TheoryCompletionEvent)>.from(
      _listeners,
    )) {
      try {
        l(event);
      } catch (_) {}
    }
  }
}
