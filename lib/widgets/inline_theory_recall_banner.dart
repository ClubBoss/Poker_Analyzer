import 'package:flutter/material.dart';

import '../models/v2/training_pack_spot.dart';
import '../services/mini_lesson_library_service.dart';
import '../services/theory_mini_lesson_navigator.dart';
import '../models/theory_mini_lesson_node.dart';

class InlineTheoryRecallBanner extends StatelessWidget {
  final TrainingPackSpot spot;
  const InlineTheoryRecallBanner({super.key, required this.spot});

  Future<TheoryMiniLessonNode?> _loadLesson(String id) async {
    await MiniLessonLibraryService.instance.loadAll();
    return MiniLessonLibraryService.instance.getById(id);
  }

  @override
  Widget build(BuildContext context) {
    final id = spot.meta['linkedTheoryId'];
    if (id == null || id is! String) return const SizedBox.shrink();
    return FutureBuilder<TheoryMiniLessonNode?>(
      future: _loadLesson(id),
      builder: (context, snapshot) {
        final lesson = snapshot.data;
        if (lesson == null) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () =>
              TheoryMiniLessonNavigator.instance.openLessonById(id),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '💡 Related Theory: ${lesson.resolvedTitle} →',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}

