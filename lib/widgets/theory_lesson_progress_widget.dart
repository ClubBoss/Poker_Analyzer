import 'package:flutter/material.dart';

import '../services/mini_lesson_library_service.dart';

class TheoryLessonProgressWidget extends StatefulWidget {
  const TheoryLessonProgressWidget({super.key});

  @override
  State<TheoryLessonProgressWidget> createState() =>
      _TheoryLessonProgressWidgetState();
}

class _TheoryLessonProgressWidgetState
    extends State<TheoryLessonProgressWidget> {
  int _total = 0;
  int _completed = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final total = await MiniLessonLibraryService.instance.getTotalLessonCount();
    final completed = await MiniLessonLibraryService.instance
        .getCompletedLessonCount();
    if (!mounted) return;
    setState(() {
      _total = total;
      _completed = completed;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _total == 0) return const SizedBox.shrink();
    final progress = _total > 0 ? _completed / _total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$_completed of $_total lessons complete'),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress),
        ],
      ),
    );
  }
}
