import '../models/theory_lesson_meta_data.dart';
import '../models/theory_mini_lesson_node.dart';

/// Extracts structured metadata such as positions and streets from
/// [TheoryMiniLessonNode] titles and tags.
class TheoryLessonMetaTagExtractorService {
  const TheoryLessonMetaTagExtractorService();

  static final RegExp _positionRegExp = RegExp(
    r'^(utg(?:\+\d)?|lj|mp|hj|co|btn|sb|bb)$',
    caseSensitive: false,
  );

  static final RegExp _villainRegExp = RegExp(
    r'vs\s*(utg(?:\+\d)?|lj|mp|hj|co|btn|sb|bb)',
    caseSensitive: false,
  );

  static final RegExp _streetRegExp = RegExp(
    r'(flop|turn|river)',
    caseSensitive: false,
  );

  static const List<String> _textures = [
    'paired',
    'wet',
    'dry',
    'acehigh',
  ];

  /// Parses [lesson] and returns extracted [TheoryLessonMetaData].
  TheoryLessonMetaData extract(TheoryMiniLessonNode lesson) {
    String? position;
    for (final tag in lesson.tags) {
      final match = _positionRegExp.firstMatch(tag.trim());
      if (match != null) {
        position = match.group(1)!.toUpperCase();
        break;
      }
    }

    String? villainPosition;
    for (final tag in lesson.tags) {
      final match = _villainRegExp.firstMatch(tag);
      if (match != null) {
        villainPosition = match.group(1)!.toUpperCase();
        break;
      }
    }
    if (villainPosition == null) {
      final match = _villainRegExp.firstMatch(lesson.title);
      if (match != null) {
        villainPosition = match.group(1)!.toUpperCase();
      }
    }

    String? street;
    for (final tag in lesson.tags) {
      final match = _streetRegExp.firstMatch(tag);
      if (match != null) {
        street = _capitalize(match.group(1)!);
        break;
      }
    }
    if (street == null) {
      final match = _streetRegExp.firstMatch(lesson.title);
      if (match != null) {
        street = _capitalize(match.group(1)!);
      }
    }

    String? boardTexture;
    for (final tag in lesson.tags) {
      final lower = tag.toLowerCase();
      for (final tex in _textures) {
        if (lower.contains(tex)) {
          boardTexture = _formatTexture(tex);
          break;
        }
      }
      if (boardTexture != null) break;
    }
    if (boardTexture == null) {
      final lower = lesson.title.toLowerCase();
      for (final tex in _textures) {
        if (lower.contains(tex)) {
          boardTexture = _formatTexture(tex);
          break;
        }
      }
    }

    return TheoryLessonMetaData(
      position: position,
      villainPosition: villainPosition,
      street: street,
      boardTexture: boardTexture,
    );
  }

  String _capitalize(String input) =>
      input[0].toUpperCase() + input.substring(1).toLowerCase();

  String _formatTexture(String input) {
    switch (input) {
      case 'acehigh':
        return 'AceHigh';
      case 'paired':
        return 'Paired';
      case 'wet':
        return 'Wet';
      case 'dry':
        return 'Dry';
      default:
        return _capitalize(input);
    }
  }
}
