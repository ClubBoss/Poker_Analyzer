import 'package:flutter/material.dart';

import '../screens/mini_lesson_screen.dart';
import 'mini_lesson_library_service.dart';
import 'navigation_service.dart';

/// Opens [MiniLessonScreen] for a lesson resolved by [theoryTag].
class TheoryMiniLessonNavigator {
  TheoryMiniLessonNavigator({
    MiniLessonLibraryService? library,
    NavigationService navigation = const NavigationService(),
  })  : _library = library ?? MiniLessonLibraryService.instance,
        _navigation = navigation;

  final MiniLessonLibraryService _library;
  final NavigationService _navigation;

  static final TheoryMiniLessonNavigator instance =
      TheoryMiniLessonNavigator();

  /// Resolves a mini lesson by [tag] and pushes [MiniLessonScreen].
  ///
  /// Uses [context] if it is valid; otherwise falls back to the global
  /// [NavigationService] context. Does nothing if the lesson cannot be found or
  /// no valid context is available.
  Future<void> openLessonByTag(String tag, [BuildContext? context]) async {
    await _library.loadAll();
    final lessons = _library.getByTags({tag});
    if (lessons.isEmpty) return;
    final lesson = lessons.first;

    BuildContext? ctx = context;
    if (ctx == null || !(ctx.mounted)) {
      ctx = _navigation.context;
    }
    if (ctx == null || !(ctx.mounted)) return;

    await Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => MiniLessonScreen(lesson: lesson)),
    );
  }

  /// Opens a lesson directly by its [id].
  Future<void> openLessonById(String id, [BuildContext? context]) async {
    await _library.loadAll();
    final lesson = _library.getById(id);
    if (lesson == null) return;

    BuildContext? ctx = context;
    if (ctx == null || !(ctx.mounted)) {
      ctx = _navigation.context;
    }
    if (ctx == null || !(ctx.mounted)) return;

    await Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => MiniLessonScreen(lesson: lesson)),
    );
  }
}

