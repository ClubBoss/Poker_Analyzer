import 'package:flutter/material.dart';

import '../models/theory_mini_lesson_node.dart';
import '../screens/theory_lesson_viewer_screen.dart';
import '../services/mini_lesson_library_service.dart';
import '../services/theory_lesson_cluster_linker_service.dart';
import '../services/theory_lesson_navigator_service.dart';

/// Provides previous/next navigation within a theory lesson cluster.
class TheoryLessonClusterNavigationWidget extends StatefulWidget {
  final String currentLessonId;
  const TheoryLessonClusterNavigationWidget({
    super.key,
    required this.currentLessonId,
  });

  @override
  State<TheoryLessonClusterNavigationWidget> createState() =>
      _TheoryLessonClusterNavigationWidgetState();
}

class _TheoryLessonClusterNavigationWidgetState
    extends State<TheoryLessonClusterNavigationWidget> {
  final TheoryLessonNavigatorService _navigator =
      TheoryLessonNavigatorService();
  final TheoryLessonClusterLinkerService _linker =
      TheoryLessonClusterLinkerService();

  String? _prev;
  String? _next;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prev = await _navigator.getPreviousLessonId(widget.currentLessonId);
    final next = await _navigator.getNextLessonId(widget.currentLessonId);
    if (!mounted) return;
    setState(() {
      _prev = prev;
      _next = next;
    });
  }

  static int _compareLessons(TheoryMiniLessonNode a, TheoryMiniLessonNode b) {
    final at = (a.title.isNotEmpty ? a.title : a.id).toLowerCase();
    final bt = (b.title.isNotEmpty ? b.title : b.id).toLowerCase();
    final cmp = at.compareTo(bt);
    return cmp != 0 ? cmp : a.id.compareTo(b.id);
  }

  Future<void> _open(String lessonId) async {
    await MiniLessonLibraryService.instance.loadAll();
    final lesson = MiniLessonLibraryService.instance.getById(lessonId);
    if (lesson == null) return;
    final cluster = await _linker.getCluster(lessonId);
    int index = 1;
    int total = 1;
    if (cluster != null) {
      final lessons = List<TheoryMiniLessonNode>.from(cluster.lessons)
        ..sort(_compareLessons);
      index = lessons.indexWhere((l) => l.id == lessonId) + 1;
      total = lessons.length;
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TheoryLessonViewerScreen(
          lesson: lesson,
          currentIndex: index,
          totalCount: total,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      if (_prev != null)
        ElevatedButton.icon(
          onPressed: () => _open(_prev!),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Previous'),
        ),
      if (_next != null)
        ElevatedButton.icon(
          onPressed: () => _open(_next!),
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Next'),
        ),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Row(
          key: ValueKey('${_prev ?? ''}-${_next ?? ''}'),
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: buttons,
        ),
      ),
    );
  }
}
