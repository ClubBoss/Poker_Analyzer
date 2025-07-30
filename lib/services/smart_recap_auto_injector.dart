import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../widgets/theory_recap_dialog.dart';
import 'recap_opportunity_detector.dart';
import 'smart_theory_recap_engine.dart';
import 'theory_recap_suppression_engine.dart';
import 'smart_theory_recap_dismissal_memory.dart';

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
  })  : detector = detector ?? RecapOpportunityDetector.instance,
        engine = engine ?? SmartTheoryRecapEngine.instance,
        suppression = suppression ?? TheoryRecapSuppressionEngine.instance,
        dismissal = dismissal ?? SmartTheoryRecapDismissalMemory.instance;

  static final SmartRecapAutoInjector instance = SmartRecapAutoInjector();

  static const _lastKey = 'smart_recap_auto_last';
  Timer? _timer;

  Future<void> start({Duration interval = const Duration(minutes: 5)}) async {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => maybeInject());
  }

  Future<void> dispose() async {
    _timer?.cancel();
  }

  Future<DateTime?> _lastInjected() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_lastKey);
    return str == null ? null : DateTime.tryParse(str);
  }

  Future<void> _markInjected() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastKey, DateTime.now().toIso8601String());
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
    if (!await detector.isGoodRecapMoment()) return;
    if (await _recentlyDismissed()) return;
    final last = await _lastInjected();
    if (last != null &&
        DateTime.now().difference(last) < const Duration(hours: 6)) {
      return;
    }
    final lesson = await engine.getNextRecap();
    if (lesson == null) return;
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
    await _markInjected();
  }
}
