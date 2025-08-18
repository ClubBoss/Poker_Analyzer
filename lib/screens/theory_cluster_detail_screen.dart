import 'package:flutter/material.dart';

import '../models/theory_lesson_cluster.dart';
import '../models/theory_mini_lesson_node.dart';
import '../services/mini_lesson_progress_tracker.dart';
import '../services/theory_cluster_progress_service.dart';
import '../widgets/theory_path_progress_bar.dart';
import '../screens/theory_lesson_preview_screen.dart';

/// Displays all lessons within a [TheoryLessonCluster].
class TheoryClusterDetailScreen extends StatefulWidget {
  final TheoryLessonCluster cluster;

  /// Optional precomputed progress to avoid recomputation when navigating
  /// from a dashboard.
  final ClusterProgress? progress;

  const TheoryClusterDetailScreen({
    super.key,
    required this.cluster,
    this.progress,
  });

  @override
  State<TheoryClusterDetailScreen> createState() =>
      _TheoryClusterDetailScreenState();
}

class _TheoryClusterDetailScreenState extends State<TheoryClusterDetailScreen> {
  final MiniLessonProgressTracker _tracker = MiniLessonProgressTracker.instance;

  late List<TheoryMiniLessonNode> _lessons;
  final Map<String, bool> _completed = {};
  bool _loading = true;
  bool _sortByDone = false;

  @override
  void initState() {
    super.initState();
    _lessons = List<TheoryMiniLessonNode>.from(widget.cluster.lessons);
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    for (final l in _lessons) {
      final done = await _tracker.isCompleted(l.id);
      _completed[l.id] = done;
    }
    if (mounted) setState(() => _loading = false);
  }

  void _toggleSort() {
    setState(() {
      _sortByDone = !_sortByDone;
      _sortLessons();
    });
  }

  void _sortLessons() {
    if (_sortByDone) {
      _lessons.sort((a, b) {
        final da = _completed[a.id] == true ? 1 : 0;
        final db = _completed[b.id] == true ? 1 : 0;
        if (da == db) return 0;
        return da.compareTo(db);
      });
    } else {
      _lessons = List<TheoryMiniLessonNode>.from(widget.cluster.lessons);
    }
  }

  Future<void> _openLesson(TheoryMiniLessonNode lesson) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TheoryLessonPreviewScreen(lessonId: lesson.id),
      ),
    );
    final done = await _tracker.isCompleted(lesson.id);
    setState(() {
      _completed[lesson.id] = done;
      _sortLessons();
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    final tags = widget.cluster.tags.join(', ');

    Widget header() {
      final total = widget.cluster.lessons.length;
      final done = _completed.values.where((v) => v).length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                tags,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          TheoryPathProgressBar(
            lessons: widget.cluster.lessons,
            dense: true,
            fullWidth: true,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Sort:'),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _toggleSort,
                icon: Icon(
                  _sortByDone ? Icons.list : Icons.checklist,
                  color: accent,
                ),
                label: Text(
                  _sortByDone ? 'Original' : 'By Status',
                  style: TextStyle(color: accent),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Theory Cluster')),
      backgroundColor: const Color(0xFF121212),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _lessons.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) return header();
                final lesson = _lessons[index - 1];
                final done = _completed[lesson.id] == true;
                return Card(
                  color: Colors.grey[850],
                  child: ListTile(
                    title: Text(lesson.resolvedTitle),
                    trailing: Icon(
                      done ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: done ? Colors.green : Colors.grey,
                    ),
                    onTap: () => _openLesson(lesson),
                  ),
                );
              },
            ),
    );
  }
}
