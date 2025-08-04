import 'package:flutter/material.dart';

import '../models/inline_theory_linked_text.dart';
import '../models/theory_mini_lesson_node.dart';
import 'mini_lesson_library_service.dart';
import 'theory_mini_lesson_navigator.dart';

class InlineTheoryLinkerService {
  InlineTheoryLinkerService({
    MiniLessonLibraryService? library,
    TheoryMiniLessonNavigator? navigator,
  }) : _library = library ?? MiniLessonLibraryService.instance,
       _navigator = navigator ?? TheoryMiniLessonNavigator.instance;

  final MiniLessonLibraryService _library;
  final TheoryMiniLessonNavigator _navigator;

  /// Parses [description] and converts matching keywords to inline links.
  ///
  /// Only lessons sharing at least one of [contextTags] are considered.
  InlineTheoryLinkedText link(
    String description, {
    List<String> contextTags = const [],
  }) {
    final candidates = _library.all.where((l) {
      if (contextTags.isEmpty) return true;
      return l.tags.any((t) => contextTags.contains(t));
    }).toList();

    final matches = <_Match>[];
    for (final lesson in candidates) {
      if (lesson.tags.isEmpty) continue;
      for (final tag in lesson.tags) {
        final regex = RegExp(
          '\\b' + RegExp.escape(tag) + '\\b',
          caseSensitive: false,
        );
        for (final m in regex.allMatches(description)) {
          matches.add(_Match(m.start, m.end, tag));
        }
      }
      // keyword match using lesson title
      final keywords = lesson.title.split(RegExp('\\s+'));
      for (final k in keywords) {
        if (k.isEmpty) continue;
        final regex = RegExp(
          '\\b' + RegExp.escape(k) + '\\b',
          caseSensitive: false,
        );
        for (final m in regex.allMatches(description)) {
          matches.add(_Match(m.start, m.end, lesson.tags.first));
        }
      }
    }

    matches.sort((a, b) => a.start.compareTo(b.start));
    final filtered = <_Match>[];
    int lastEnd = -1;
    for (final m in matches) {
      if (m.start >= lastEnd) {
        filtered.add(m);
        lastEnd = m.end;
      }
    }

    final chunks = <InlineTextChunk>[];
    int index = 0;
    for (final m in filtered) {
      if (m.start > index) {
        chunks.add(
          InlineTextChunk(text: description.substring(index, m.start)),
        );
      }
      final text = description.substring(m.start, m.end);
      chunks.add(
        InlineTextChunk(
          text: text,
          onTap: () => _navigator.openLessonByTag(m.tag),
        ),
      );
      index = m.end;
    }
    if (index < description.length) {
      chunks.add(InlineTextChunk(text: description.substring(index)));
    }
    return InlineTheoryLinkedText(chunks);
  }

  /// Returns lessons related to the provided [tags].
  Future<List<TheoryMiniLessonNode>> extractRelevantLessons(
    List<String> tags,
  ) async {
    await _library.loadAll();
    return _library.findByTags(tags);
  }
}

class _Match {
  final int start;
  final int end;
  final String tag;
  _Match(this.start, this.end, this.tag);
}
