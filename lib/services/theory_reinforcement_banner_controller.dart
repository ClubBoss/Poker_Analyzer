import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';

import '../models/theory_mini_lesson_node.dart';
import 'mini_lesson_library_service.dart';
import 'recap_completion_tracker.dart';
import 'theory_boost_trigger_service.dart';

/// Listens for recap completions and surfaces a soft banner suggestion
/// when a related theory lesson should be reviewed but auto-launch is
/// suppressed.
class TheoryReinforcementBannerController extends ChangeNotifier {
  final RecapCompletionTracker tracker;
  final TheoryBoostTriggerService trigger;
  final MiniLessonLibraryService library;
  final Duration cooldown;

  TheoryReinforcementBannerController({
    RecapCompletionTracker? tracker,
    TheoryBoostTriggerService? trigger,
    MiniLessonLibraryService? library,
    this.cooldown = const Duration(hours: 6),
  }) : tracker = tracker ?? RecapCompletionTracker.instance,
       trigger = trigger ?? TheoryBoostTriggerService.instance,
       library = library ?? MiniLessonLibraryService.instance {
    _sub = this.tracker.onCompletion.listen(_handle);
  }

  StreamSubscription<RecapCompletionLog>? _sub;
  TheoryMiniLessonNode? _lesson;
  DateTime _lastShown = DateTime.fromMillisecondsSinceEpoch(0);
  bool _dismissed = false;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// Returns the lesson to be shown in the banner if any.
  TheoryMiniLessonNode? getPendingBannerLesson() => _lesson;

  /// True when a banner should be visible.
  bool shouldShowBanner() => _lesson != null && !_dismissed;

  /// Marks the current banner as dismissed.
  void markBannerDismissed() {
    if (_lesson == null) return;
    _lesson = null;
    _dismissed = true;
    notifyListeners();
  }

  bool _underCooldown() => DateTime.now().difference(_lastShown) < cooldown;

  Future<void> _handle(RecapCompletionLog log) async {
    if (_underCooldown()) return;
    if (!await trigger.shouldTriggerBoost(log.tag)) return;
    await library.loadAll();
    final lesson = library.findByTags([log.tag]).firstOrNull;
    if (lesson == null) return;
    _lesson = lesson;
    _dismissed = false;
    _lastShown = DateTime.now();
    notifyListeners();
  }
}
