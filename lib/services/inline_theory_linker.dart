import 'package:flutter/material.dart';

import 'mini_lesson_library_service.dart';
import 'theory_mini_lesson_navigator.dart';

/// Represents a link to a theory mini lesson.
class InlineTheoryLink {
  final String title;
  final VoidCallback onTap;

  InlineTheoryLink({required this.title, required this.onTap});
}

/// Resolves theory links for training spots based on [theoryTags].
class InlineTheoryLinker {
  InlineTheoryLinker({
    MiniLessonLibraryService? library,
    TheoryMiniLessonNavigator? navigator,
    List<String>? priorityTags,
  })  : _library = library ?? MiniLessonLibraryService.instance,
        _navigator = navigator ?? TheoryMiniLessonNavigator.instance,
        _priorityTags = priorityTags ?? const ['cbet', 'probe'];

  final MiniLessonLibraryService _library;
  final TheoryMiniLessonNavigator _navigator;
  final List<String> _priorityTags;

  /// Returns an [InlineTheoryLink] for [theoryTags] or `null` if no lesson found.
  InlineTheoryLink? getLink(List<String> theoryTags) {
    final tags = <String>{
      for (final t in theoryTags) t.trim().toLowerCase(),
    }..removeWhere((t) => t.isEmpty);
    if (tags.isEmpty) return null;

    String? chosen;
    for (final p in _priorityTags) {
      if (tags.contains(p)) {
        chosen = p;
        break;
      }
    }
    chosen ??= tags.first;

    final lessons = _library.getByTags({chosen});
    if (lessons.isEmpty) return null;
    final lesson = lessons.first;
    return InlineTheoryLink(
      title: lesson.title,
      onTap: () => _navigator.openLessonByTag(chosen!),
    );
  }
}
