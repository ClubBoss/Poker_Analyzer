import 'dart:async';

import 'package:flutter/widgets.dart';

import 'skill_tag_decay_tracker.dart';
import 'recap_tag_analytics_service.dart';
import 'smart_recap_banner_controller.dart';
import 'theory_boost_recap_linker.dart';
import 'mini_lesson_library_service.dart';

/// Background scheduler that precomputes smart recap suggestions.
class SmartRecapScheduler with WidgetsBindingObserver {
  SmartRecapScheduler({
    required this.decay,
    required this.analytics,
    required this.controller,
    TheoryBoostRecapLinker? theoryLinker,
    MiniLessonLibraryService? library,
  }) : theoryLinker = theoryLinker ?? const TheoryBoostRecapLinker(),
       library = library ?? MiniLessonLibraryService.instance;

  final SkillTagDecayTracker decay;
  final RecapTagAnalyticsService analytics;
  final SmartRecapBannerController controller;
  final TheoryBoostRecapLinker theoryLinker;
  final MiniLessonLibraryService library;

  Timer? _timer;

  Future<void> start({Duration interval = const Duration(hours: 1)}) async {
    WidgetsBinding.instance.addObserver(this);
    await _evaluate();
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _evaluate());
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _evaluate();
    }
  }

  Future<void> _evaluate() async {
    final tags = await decay.getDecayingTags();
    if (tags.isEmpty) return;
    final perf = await analytics.computeRecapTagImprovements();
    String tag = tags.first;
    double best = perf[tag]?.improvement ?? double.infinity;
    for (final t in tags.skip(1)) {
      final val = perf[t]?.improvement ?? double.infinity;
      if (val < best) {
        best = val;
        tag = t;
      }
    }
    var lesson = await theoryLinker.fetchLesson(tag);
    lesson ??= (await library.loadAll(), library.findByTags([tag]).firstOrNull);
    if (lesson != null) {
      await controller.queueBannerFor(lesson);
    }
  }
}
