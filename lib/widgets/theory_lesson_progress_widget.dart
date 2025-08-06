import 'dart:async';

import 'package:flutter/material.dart';

import '../services/theory_lesson_progress_tracker_service.dart';

class TheoryLessonProgressWidget extends StatefulWidget {
  const TheoryLessonProgressWidget({super.key});

  @override
  State<TheoryLessonProgressWidget> createState() =>
      _TheoryLessonProgressWidgetState();
}

class _TheoryLessonProgressWidgetState
    extends State<TheoryLessonProgressWidget> {
  final _tracker = TheoryLessonProgressTrackerService.instance;
  TheoryLessonProgressState? _state;
  StreamSubscription<TheoryLessonProgressState>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = _tracker.stream.listen((s) {
      if (!mounted) return;
      setState(() => _state = s);
    });
    _tracker.refresh();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _state;
    if (s == null || s.total == 0) return const SizedBox.shrink();
    final progress = s.total > 0 ? s.completed / s.total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${s.completed} of ${s.total} lessons complete'),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress),
        ],
      ),
    );
  }
}
