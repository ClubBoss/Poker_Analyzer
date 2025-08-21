import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/theory_mini_lesson_node.dart';
import 'theory_inbox_banner_engine.dart';

/// Controls visibility of the inbox theory banner.
class TheoryInboxBannerController extends ChangeNotifier {
  final TheoryInboxBannerEngine engine;

  TheoryInboxBannerController({TheoryInboxBannerEngine? engine})
      : engine = engine ?? TheoryInboxBannerEngine.instance;

  TheoryMiniLessonNode? _lesson;
  Timer? _timer;

  /// Starts periodic checks for inbox banner.
  Future<void> start({Duration interval = const Duration(hours: 12)}) async {
    _timer?.cancel();
    await _check();
    if (interval > Duration.zero) {
      _timer = Timer.periodic(interval, (_) => _check());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    await engine.run();
    _lesson = engine.lesson;
    notifyListeners();
  }

  /// Whether inbox banner should be shown.
  bool shouldShowInboxBanner() => _lesson != null;

  /// Recommended lesson for the banner.
  TheoryMiniLessonNode? getLesson() => _lesson;
}
