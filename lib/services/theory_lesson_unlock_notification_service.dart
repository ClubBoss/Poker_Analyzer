import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mini_lesson_library_service.dart';
import '../screens/theory_lesson_viewer_screen.dart';

/// Shows a notification when new theory lessons become unlocked.
class TheoryLessonUnlockNotificationService {
  TheoryLessonUnlockNotificationService({MiniLessonLibraryService? library})
      : _library = library ?? MiniLessonLibraryService.instance;

  final MiniLessonLibraryService _library;

  /// Key used to store unlocked lesson ids in [SharedPreferences].
  static const storageKey = 'unlocked_theory_lessons';

  /// Compares [currentUnlockedLessonIds] with previously stored ids and shows
  /// notifications for newly unlocked lessons.
  Future<void> checkAndNotify(
    List<String> currentUnlockedLessonIds,
    BuildContext context,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final previous = prefs.getStringList(storageKey)?.toSet() ?? <String>{};
    final current = currentUnlockedLessonIds.toSet();
    final newIds = current.difference(previous);

    if (newIds.isEmpty) {
      await prefs.setStringList(storageKey, currentUnlockedLessonIds);
      return;
    }

    await _library.loadAll();
    final total = await _library.getTotalLessonCount();
    final completed = await _library.getCompletedLessonCount();
    for (final id in newIds) {
      if (!context.mounted) break;
      final lesson = _library.getById(id);
      final title = lesson?.title ?? id;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'New lesson unlocked: $title\n($completed of $total lessons complete)',
          ),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              if (!context.mounted || lesson == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TheoryLessonViewerScreen(
                    lesson: lesson,
                    currentIndex: 1,
                    totalCount: 1,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    await prefs.setStringList(storageKey, currentUnlockedLessonIds);
  }
}

