import '../models/theory_mini_lesson_node.dart';

/// Generates placeholder content for [TheoryMiniLessonNode]s based on tags and
/// metadata such as `stage` or `targetStreet`.
class TheoryMiniLessonContentTemplateService {
  /// Mapping from composite keys to content templates.
  ///
  /// Keys may combine tags and metadata separated by commas, e.g.
  /// `'BTN vs BB, Flop CBet'`.
  final Map<String, String> templateMap;

  TheoryMiniLessonContentTemplateService({Map<String, String>? templateMap})
      : templateMap = templateMap ?? _defaultTemplates;

  /// Returns a new [TheoryMiniLessonNode] with its `content` field populated
  /// using a matching template. If no template is found or [node.content] is
  /// already non-empty, the original [node] is returned.
  TheoryMiniLessonNode withGeneratedContent(TheoryMiniLessonNode node) {
    if (node.content.isNotEmpty) return node;
    final template = _matchTemplate(node);
    if (template == null) return node;
    return TheoryMiniLessonNode(
      id: node.id,
      refId: node.refId,
      title: node.title,
      content: template,
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

  static const Map<String, String> _defaultTemplates = {
    'BTN vs BB, Flop CBet':
        "In this spot, you're playing BTN against BB on the flop. Your goal is to decide whether to continuation bet...",
  };
}

