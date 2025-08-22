import '../core/error_logger.dart';
import '../core/training/generation/yaml_reader.dart';
import '../models/mini_lesson_pack_model.dart';
import '../models/theory_mini_lesson_node.dart';

/// Loads YAML mini lesson packs into [MiniLessonPackModel] objects.
class MiniLessonPackImporter {
  const MiniLessonPackImporter({YamlReader? yamlReader, ErrorLogger? logger})
    : _reader = yamlReader ?? const YamlReader(),
      _logger = logger ?? ErrorLogger.instance;

  final YamlReader _reader;
  final ErrorLogger _logger;

  /// Parses [yamlContent] into a [MiniLessonPackModel]. Returns `null` on error.
  MiniLessonPackModel? importFromYaml(
    String yamlContent, {
    bool validate = true,
  }) {
    try {
      final map = _reader.read(yamlContent);
      return _fromMap(map, validate: validate);
    } catch (e, st) {
      _logger.logError('MiniLessonPackImporter failed to parse YAML', e, st);
      return null;
    }
  }

  MiniLessonPackModel _fromMap(
    Map<String, dynamic> map, {
    required bool validate,
  }) {
    final packId = map['pack_id']?.toString() ?? '';
    final title = map['title']?.toString() ?? '';
    final type = map['type']?.toString() ?? '';

    final lessons = <TheoryMiniLessonNode>[];
    final ids = <String>{};
    final rawLessons = map['lessons'];
    if (rawLessons is List) {
      for (final l in rawLessons) {
        if (l is! Map) {
          _logger.logError('Malformed lesson entry: $l');
          continue;
        }
        try {
          final node = TheoryMiniLessonNode.fromYaml(
            Map<String, dynamic>.from(l),
          );
          if (node.id.isEmpty) {
            _logger.logError('Mini lesson missing id');
            continue;
          }
          if (validate && !ids.add(node.id)) {
            _logger.logError('Duplicate lesson id ${node.id}');
            continue;
          }
          lessons.add(node);
        } catch (e, st) {
          _logger.logError('Failed to parse mini lesson: ${l['id']}', e, st);
        }
      }
    }

    if (validate) {
      if (packId.isEmpty) _logger.logError('Missing pack_id');
      if (title.isEmpty) _logger.logError('Missing title');
    }

    return MiniLessonPackModel(
      packId: packId,
      title: title,
      type: type,
      lessons: lessons,
    );
  }
}
