import 'package:flutter/material.dart';

import '../models/v2/training_pack_spot.dart';
import '../services/mini_lesson_library_service.dart';

/// Simple debug widget that lists theory lessons linked to a spot.
class LinkedTheoryPreviewWidget extends StatelessWidget {
  final TrainingPackSpot spot;
  final MiniLessonLibraryService library;

  const LinkedTheoryPreviewWidget({
    super.key,
    required this.spot,
    MiniLessonLibraryService? library,
  }) : library = library ?? MiniLessonLibraryService.instance;

  @override
  Widget build(BuildContext context) {
    final ids =
        (spot.meta['linkedTheoryLessonIds'] as List?)?.cast<String>() ?? [];
    if (ids.isEmpty) return const SizedBox.shrink();
    return Card(
      child: ListTile(
        title: const Text('Linked Theory Lessons'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final id in ids)
              Text(library.getById(id)?.resolvedTitle ?? id),
          ],
        ),
      ),
    );
  }
}
