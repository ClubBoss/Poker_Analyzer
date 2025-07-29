import 'dart:async';

import 'package:flutter/material.dart';

import '../models/theory_mini_lesson_node.dart';
import '../services/mini_lesson_library_service.dart';
import '../services/lesson_search_engine.dart';
import '../services/mini_lesson_progress_tracker.dart';
import '../screens/theory_lesson_preview_screen.dart';

/// Search bar widget for quick theory lesson lookup.
class TheoryLessonSearchBar extends StatefulWidget {
  const TheoryLessonSearchBar({super.key});

  @override
  State<TheoryLessonSearchBar> createState() => _TheoryLessonSearchBarState();
}

class _TheoryLessonSearchBarState extends State<TheoryLessonSearchBar> {
  final _controller = TextEditingController();
  final _engine = LessonSearchEngine();
  List<TheoryMiniLessonNode> _results = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
    _controller.addListener(_onChanged);
  }

  Future<void> _load() async {
    await MiniLessonLibraryService.instance.loadAll();
    _search('');
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _search(_controller.text);
    });
  }

  void _search(String q) {
    setState(() => _results = _engine.search(q, limit: 10));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open(TheoryMiniLessonNode lesson) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TheoryLessonPreviewScreen(lessonId: lesson.id),
      ),
    );
  }

  Widget _buildRow(BuildContext context, TheoryMiniLessonNode lesson) {
    final accent = Theme.of(context).colorScheme.secondary;
    return FutureBuilder<bool>(
      future: MiniLessonProgressTracker.instance.isCompleted(lesson.id),
      builder: (context, snapshot) {
        final done = snapshot.data == true;
        return ListTile(
          title: Text(lesson.resolvedTitle),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: LinearProgressIndicator(
              value: done ? 1.0 : 0.0,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
              minHeight: 6,
            ),
          ),
          trailing: ElevatedButton(
            onPressed: () => _open(lesson),
            style: ElevatedButton.styleFrom(backgroundColor: accent),
            child: const Text('Start'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          decoration: const InputDecoration(hintText: 'Search lessons'),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _results.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final lesson = _results[index];
              return _buildRow(context, lesson);
            },
          ),
        ),
      ],
    );
  }
}
