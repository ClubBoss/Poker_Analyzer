import 'package:flutter/material.dart';

import '../models/learning_path_block.dart';
import '../services/mini_lesson_library_service.dart';
import '../screens/mini_lesson_screen.dart';

/// Renders an injected theory [LearningPathBlock] with CTA to open the lesson.
class InjectedTheoryBlockRenderer extends StatefulWidget {
  final LearningPathBlock block;
  const InjectedTheoryBlockRenderer({super.key, required this.block});

  @override
  State<InjectedTheoryBlockRenderer> createState() =>
      _InjectedTheoryBlockRendererState();
}

class _InjectedTheoryBlockRendererState
    extends State<InjectedTheoryBlockRenderer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _anim.forward();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _openLesson() async {
    await MiniLessonLibraryService.instance.loadAll();
    final lesson =
        MiniLessonLibraryService.instance.getById(widget.block.lessonId);
    if (lesson == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MiniLessonScreen(lesson: lesson)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return FadeTransition(
      opacity: _anim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.block.header,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.block.content,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _openLesson,
                style: ElevatedButton.styleFrom(backgroundColor: accent),
                child: Text(widget.block.ctaLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
