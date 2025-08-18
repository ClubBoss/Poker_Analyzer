import '../models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/constants/theory_lesson_template_map.dart';

/// Generates placeholder content for [TheoryMiniLessonNode]s based on tags and
/// metadata such as `stage` or `targetStreet`.
class TheoryMiniLessonContentTemplateService {
  /// Mapping from composite keys to content templates.
  ///
  /// Keys may combine tags and metadata separated by commas, e.g.
  /// `'BTN vs BB, Flop CBet'`.
  final Map<String, String> templateMap;

  const TheoryMiniLessonContentTemplateService({
    Map<String, String>? templateMap,
  }) : templateMap = templateMap ?? theoryLessonTemplateMap;

  /// Returns a new [TheoryMiniLessonNode] with its `content` field populated
  /// using a matching template. If no template is found or [node.content] is
  /// already non-empty, the original [node] is returned.
  TheoryMiniLessonNode withGeneratedContent(TheoryMiniLessonNode node) {
    if (node.content.isNotEmpty) return node;
    final template = _matchTemplate(node);
    if (template == null) return node;
    final filled = _fillPlaceholders(template, node);
    return TheoryMiniLessonNode(
      id: node.id,
      refId: node.refId,
      title: node.title,
      content: filled,
      tags: List<String>.from(node.tags),
      stage: node.stage,
      targetStreet: node.targetStreet,
      nextIds: List<String>.from(node.nextIds),
      linkedPackIds: List<String>.from(node.linkedPackIds),
      recoveredFromMistake: node.recoveredFromMistake,
    );
  }

  /// Populates a list of lessons using [withGeneratedContent].
  List<TheoryMiniLessonNode> withGeneratedContentForAll(
    List<TheoryMiniLessonNode> nodes,
  ) {
    return [for (final n in nodes) withGeneratedContent(n)];
  }

  String? _matchTemplate(TheoryMiniLessonNode node) {
    for (final key in _candidateKeys(node)) {
      final template = templateMap[key];
      if (template != null) return template;
    }
    return null;
  }

  Iterable<String> _candidateKeys(TheoryMiniLessonNode node) sync* {
    final stage = node.stage;
    final street = node.targetStreet;
    final tagsKey = node.tags.join(', ');
    if (tagsKey.isNotEmpty) {
      if (stage != null && street != null) {
        yield '$tagsKey, $stage, $street';
      }
      if (stage != null) yield '$tagsKey, $stage';
      if (street != null) yield '$tagsKey, $street';
      yield tagsKey;
    }
    if (stage != null && street != null) yield '$stage, $street';
    if (stage != null) yield stage;
    if (street != null) yield street;
  }

  String _fillPlaceholders(String template, TheoryMiniLessonNode node) {
    var result = template;

    final posTag = node.tags.firstWhere(
      (t) => t.contains(' vs '),
      orElse: () => '',
    );
    if (posTag.isNotEmpty) {
      final parts = posTag.split(' vs ');
      final hero = parts.first;
      final villain = parts.length > 1 ? parts[1] : '';
      result = result.replaceAll('{position}', hero);
      result = result.replaceAll('{villainPosition}', villain);
    } else {
      result = result.replaceAll('{position}', '');
      result = result.replaceAll('{villainPosition}', '');
    }

    final boardTexture = _extractBoardTexture(node.tags);
    result = result.replaceAll('{boardTexture}', boardTexture);

    result = result.replaceAll('{stage}', node.stage ?? '');
    result = result.replaceAll('{targetStreet}', node.targetStreet ?? '');

    return result;
  }

  String _extractBoardTexture(List<String> tags) {
    const textures = {
      'Wet Board',
      'Dry Board',
      'Paired',
      'Monotone',
      'Rainbow',
    };
    for (final t in tags) {
      if (textures.contains(t)) return t;
    }
    return '';
  }
}
