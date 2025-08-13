import 'package:flutter/material.dart';

import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_v2.dart';
import '../models/theory_lesson_cluster.dart';
import '../models/theory_mini_lesson_node.dart';
import '../services/mini_lesson_library_service.dart';
import '../services/theory_lesson_cluster_linker_service.dart';
import '../theme/app_colors.dart';
import 'theory_lesson_preview_screen.dart';
import 'training_session_screen.dart';

/// Displays a lightweight preview of theory spots before starting a session.
class TheoryPackPreviewScreen extends StatefulWidget {
  final TrainingPackTemplateV2 template;
  const TheoryPackPreviewScreen({super.key, required this.template});

  @override
  State<TheoryPackPreviewScreen> createState() =>
      _TheoryPackPreviewScreenState();
}

class _TheoryPackPreviewScreenState extends State<TheoryPackPreviewScreen> {
  late final Future<TheoryLessonCluster?> _clusterFuture;
  final TheoryLessonClusterLinkerService _linker =
      TheoryLessonClusterLinkerService();

  @override
  void initState() {
    super.initState();
    _clusterFuture = _loadCluster();
  }

  Future<TheoryLessonCluster?> _loadCluster() async {
    await MiniLessonLibraryService.instance.loadAll();
    TheoryMiniLessonNode? lesson;
    for (final l in MiniLessonLibraryService.instance.all) {
      if (l.linkedPackIds.contains(widget.template.id)) {
        lesson = l;
        break;
      }
    }
    if (lesson == null) return null;
    return _linker.getCluster(lesson.id);
  }

  Future<void> _openLesson(TheoryMiniLessonNode lesson) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TheoryLessonPreviewScreen(lessonId: lesson.id),
      ),
    );
    setState(() {});
  }

  Future<int> _completedLessonCount(TheoryLessonCluster cluster) async {
    var done = 0;
    for (final l in cluster.lessons) {
      if (await MiniLessonLibraryService.instance.isLessonCompleted(l.id)) {
        done++;
      }
    }
    return done;
  }

  Future<TheoryMiniLessonNode?> _firstIncompleteLesson(
      TheoryLessonCluster cluster) async {
    for (final l in cluster.lessons) {
      if (!await MiniLessonLibraryService.instance.isLessonCompleted(l.id)) {
        return l;
      }
    }
    return null;
  }

  Widget _clusterPreview() {
    return FutureBuilder<TheoryLessonCluster?>(
      future: _clusterFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final cluster = snapshot.data;
        return ExpansionTile(
          title: const Text('Related Theory Cluster'),
          children: cluster == null
              ? [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No related theory cluster available'),
                  ),
                ]
              : [
                  FutureBuilder<TheoryMiniLessonNode?>(
                    future: _firstIncompleteLesson(cluster),
                    builder: (context, lessonSnap) {
                      final firstIncomplete = lessonSnap.data;
                      if (firstIncomplete == null) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ElevatedButton(
                          onPressed: () => _openLesson(firstIncomplete),
                          child: const Text('Continue lesson'),
                        ),
                      );
                    },
                  ),
                  FutureBuilder<int>(
                    future: _completedLessonCount(cluster),
                    builder: (context, countSnap) {
                      final count = countSnap.data ?? 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text(
                          '$count of ${cluster.lessons.length} lessons complete',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      );
                    },
                  ),
                  ...cluster.lessons
                      .map(
                        (l) => FutureBuilder<bool>(
                          future: MiniLessonLibraryService.instance
                              .isLessonCompleted(l.id),
                          builder: (context, doneSnap) {
                            final done = doneSnap.data ?? false;
                            return ListTile(
                              leading: done
                                  ? const Icon(Icons.check_circle,
                                      color: Colors.green)
                                  : null,
                              title: Text(
                                l.resolvedTitle,
                                style: TextStyle(
                                  color: done ? Colors.green : null,
                                ),
                              ),
                              onTap: () => _openLesson(l),
                            );
                          },
                        ),
                      )
                      .toList(),
                ],
        );
      },
    );
  }

  void _start(BuildContext context) {
    final pack =
        TrainingPackV2.fromTemplate(widget.template, widget.template.id);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => TrainingSessionScreen(pack: pack)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.template.name)),
      backgroundColor: AppColors.background,
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: widget.template.spots.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          if (i == 0) return _clusterPreview();
          final spot = widget.template.spots[i - 1];
          final subtitle = spot.explanation?.split('\n').first ?? '';
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spot.title.isNotEmpty ? spot.title : 'Spot $i',
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          subtitle,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => _start(context),
            child: const Text('Начать изучение'),
          ),
        ),
      ),
    );
  }
}
