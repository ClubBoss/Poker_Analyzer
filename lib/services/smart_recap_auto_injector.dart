import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../widgets/theory_recap_dialog.dart';
import 'recap_opportunity_detector.dart';
import 'smart_theory_recap_engine.dart';
import 'theory_recap_suppression_engine.dart';
import 'smart_theory_recap_dismissal_memory.dart';
import 'theory_injection_horizon_service.dart';
import 'theory_priority_gatekeeper_service.dart';
import 'booster_queue_pressure_monitor.dart';

/// Automatically shows recap dialogs at ideal moments without user interaction.
class SmartRecapAutoInjector {
  final RecapOpportunityDetector detector;
  final SmartTheoryRecapEngine engine;
  final TheoryRecapSuppressionEngine suppression;
  final SmartTheoryRecapDismissalMemory dismissal;

  SmartRecapAutoInjector({
    RecapOpportunityDetector? detector,
    SmartTheoryRecapEngine? engine,
    TheoryRecapSuppressionEngine? suppression,
    SmartTheoryRecapDismissalMemory? dismissal,
  }) : detector = detector ?? RecapOpportunityDetector.instance,
       engine = engine ?? SmartTheoryRecapEngine.instance,
       suppression = suppression ?? TheoryRecapSuppressionEngine.instance,
       dismissal = dismissal ?? SmartTheoryRecapDismissalMemory.instance;

  static final SmartRecapAutoInjector instance = SmartRecapAutoInjector();

  Timer? _timer;

  Future<void> start({Duration interval = const Duration(minutes: 5)}) async {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => maybeInject());
  }

  Future<void> dispose() async {
    _timer?.cancel();
  }

  Future<bool> _recentlyDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('smart_theory_recap_dismissed');
    if (str == null) return false;
    final ts = DateTime.tryParse(str);
    if (ts == null) return false;
    return DateTime.now().difference(ts) < const Duration(hours: 12);
  }

  /// Checks for recap opportunity and shows dialog if suitable.
  Future<void> maybeInject() async {
    if (await BoosterQueuePressureMonitor.instance.isOverloaded()) return;
    if (!await detector.isGoodRecapMoment()) return;
    if (await _recentlyDismissed()) return;
    if (!await TheoryInjectionHorizonService.instance.canInject('recap')) {
      return;
    }
    final lesson = await engine.getNextRecap();
    if (lesson == null) return;
    if (await TheoryPriorityGatekeeperService.instance.isBlocked(lesson.id)) {
      return;
    }
    if (await suppression.shouldSuppress(
      lessonId: lesson.id,
      trigger: 'autoInject',
    )) {
      return;
    }
    if (await dismissal.shouldThrottle('lesson:${lesson.id}')) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    await showTheoryRecapDialog(
      ctx,
      lessonId: lesson.id,
      trigger: 'autoInject',
    );
    await TheoryInjectionHorizonService.instance.markInjected('recap');
  }
}
