import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/theory_mini_lesson_node.dart';
import '../screens/mini_lesson_screen.dart';
import '../widgets/theory_recall_overlay_banner.dart';
import 'overlay_booster_manager.dart';
import 'theory_booster_recall_engine.dart';

/// Shows gentle overlay reminders for unlaunched theory boosters.
class TheoryRecallOverlayScheduler with WidgetsBindingObserver {
  final TheoryBoosterRecallEngine recall;
  final Duration cooldown;

  TheoryRecallOverlayScheduler({
    TheoryBoosterRecallEngine? recall,
    this.cooldown = const Duration(hours: 12),
  }) : recall = recall ?? TheoryBoosterRecallEngine.instance;

  OverlayEntry? _entry;
  DateTime _lastShown = DateTime.fromMillisecondsSinceEpoch(0);
  bool _shownThisSession = false;
  bool _checking = false;

  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
    await _check();
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    _remove();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _shownThisSession = false;
      _check();
    }
  }

  bool _anotherOverlayActive(BuildContext context) {
    final booster = context.read<OverlayBoosterManager>();
    return booster.isShowing || (navigatorKey.currentState?.canPop() ?? false);
  }

  Future<void> _check() async {
    if (_checking || _shownThisSession) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    if (_anotherOverlayActive(ctx)) return;
    if (DateTime.now().difference(_lastShown) < cooldown) return;
    _checking = true;
    try {
      final lessons = await recall.recallUnlaunched();
      if (lessons.isEmpty) return;
      final lesson = _oldest(lessons);
      final overlay = Overlay.of(ctx);
      void dismiss() => _remove();
      Future<void> open() async {
        _remove();
        await TheoryBoosterRecallEngine.instance.recordLaunch(lesson.id);
        await Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => MiniLessonScreen(lesson: lesson)),
        );
      }
      _entry = OverlayEntry(
        builder: (_) => TheoryRecallOverlayBanner(
          title: lesson.resolvedTitle,
          onDismiss: dismiss,
          onOpen: open,
        ),
      );
      overlay.insert(_entry!);
      _lastShown = DateTime.now();
      _shownThisSession = true;
    } finally {
      _checking = false;
    }
  }

  TheoryMiniLessonNode _oldest(List<TheoryMiniLessonNode> lessons) {
    lessons.sort((a, b) => a.id.compareTo(b.id));
    return lessons.first;
  }

  void _remove() {
    _entry?.remove();
    _entry = null;
  }
}
