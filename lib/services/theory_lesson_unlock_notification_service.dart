import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mini_lesson_library_service.dart';

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
    for (final id in newIds) {
      if (!context.mounted) break;
      final title = _library.getById(id)?.title ?? id;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('New lesson unlocked: $title')),
      );
    }

    await prefs.setStringList(storageKey, currentUnlockedLessonIds);
  }
}

