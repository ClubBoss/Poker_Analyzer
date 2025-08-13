import 'package:flutter/material.dart';

import '../models/theory_mini_lesson_node.dart';
import '../services/mini_lesson_library_service.dart';
import '../widgets/theory_lesson_preview_tile.dart';
import 'theory_lesson_viewer_screen.dart';

/// Displays a lightweight preview for a [TheoryMiniLessonNode].
class TheoryLessonPreviewScreen extends StatefulWidget {
  final String lessonId;
  const TheoryLessonPreviewScreen({super.key, required this.lessonId});

  @override
  State<TheoryLessonPreviewScreen> createState() =>
      _TheoryLessonPreviewScreenState();
}

class _TheoryLessonPreviewScreenState extends State<TheoryLessonPreviewScreen> {
  late Future<TheoryMiniLessonNode?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<TheoryMiniLessonNode?> _load() async {
    await MiniLessonLibraryService.instance.loadAll();
    return MiniLessonLibraryService.instance.getById(widget.lessonId);
  }

  void _open(TheoryMiniLessonNode lesson) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TheoryLessonViewerScreen(
          lesson: lesson,
          currentIndex: 1,
          totalCount: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      appBar: AppBar(title: const Text('Предпросмотр урока')),
      backgroundColor: const Color(0xFF121212),
      body: FutureBuilder<TheoryMiniLessonNode?>(
        future: _future,
        builder: (context, snapshot) {
          final lesson = snapshot.data;
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (lesson == null) {
            return const Center(child: Text('Lesson not found'));
          }
          return Column(
            children: [
              TheoryLessonPreviewTile(node: lesson),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _open(lesson),
                    style: ElevatedButton.styleFrom(backgroundColor: accent),
                    child: const Text('Начать'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
