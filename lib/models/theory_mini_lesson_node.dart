import 'learning_path_node.dart';
import '../services/theory_content_service.dart';

/// Node representing a short theory mini lesson within the learning path graph.
class TheoryMiniLessonNode implements LearningPathNode {
  @override
  final String id;

  @override
  final bool recoveredFromMistake;

  /// Optional reference id of shared theory content.
  final String? refId;

  /// Display title of the lesson.
  final String title;

  /// Markdown or plain text content of the lesson.
  final String content;

  /// Tags associated with this mini lesson.
  final List<String> tags;

  /// Optional poker street this lesson targets such as `flop` or `turn`.
  ///
  /// When provided, linking services may use this to match lessons to training
  /// spots on the same street.
  final String? targetStreet;

  /// Optional stage identifier like `level2`.
  final String? stage;

  /// IDs of nodes unlocked after reading this lesson.
  final List<String> nextIds;

  /// Ids of training packs linked to this lesson.
  List<String> linkedPackIds;

  /// Whether the lesson's content was generated automatically. When true,
  /// regeneration should not overwrite manually edited text unless explicitly
  /// requested.
  final bool autoContent;

  const TheoryMiniLessonNode({
    required this.id,
    this.refId,
    required this.title,
    required this.content,
    this.stage,
    this.targetStreet,
    List<String>? tags,
    List<String>? nextIds,
    List<String>? linkedPackIds,
    this.recoveredFromMistake = false,
    this.autoContent = false,
  })  : tags = tags ?? const [],
        nextIds = nextIds ?? const [],
        linkedPackIds = linkedPackIds ?? const [];

  /// Returns [title] or the referenced block's title when empty.
  String get resolvedTitle {
    if (title.isNotEmpty) return title;
    if (refId == null) return title;
    final block = TheoryContentService.instance.get(refId!);
    return block?.title ?? title;
  }

  /// Returns [content] or the referenced block's content when empty.
  String get resolvedContent {
    if (content.isNotEmpty) return content;
    if (refId == null) return content;
    final block = TheoryContentService.instance.get(refId!);
    return block?.content ?? content;
  }

  factory TheoryMiniLessonNode.fromYaml(Map yaml) {
    final tags = <String>[];
    final rawTags = yaml['tags'];
    if (rawTags is List) {
      for (final t in rawTags) {
        tags.add(t.toString());
      }
    }
    final rawNext = yaml['nextIds'] ?? yaml['next'];
    final nextIds = <String>[
      for (final v in (rawNext as List? ?? [])) v.toString()
    ];
    final linked = <String>[
      for (final v in (yaml['linkedPackIds'] as List? ?? [])) v.toString()
    ];
    return TheoryMiniLessonNode(
      id: yaml['id']?.toString() ?? '',
      refId: yaml['refId']?.toString(),
      title: yaml['title']?.toString() ?? '',
      content: yaml['content']?.toString() ?? '',
      tags: tags,
      targetStreet: yaml['targetStreet']?.toString(),
      stage: yaml['stage']?.toString(),
      nextIds: nextIds,
      linkedPackIds: linked,
      recoveredFromMistake: yaml['recoveredFromMistake'] as bool? ?? false,
      autoContent: yaml['autoContent'] as bool? ?? false,
    );
  }

  factory TheoryMiniLessonNode.fromJson(Map<String, dynamic> json) {
    final tags = <String>[
      for (final t in (json['tags'] as List? ?? [])) t.toString()
    ];
    final rawNext = json['nextIds'] ?? json['next'];
    final nextIds = <String>[
      for (final v in (rawNext as List? ?? [])) v.toString()
    ];
    final linked = <String>[
      for (final v in (json['linkedPackIds'] as List? ?? [])) v.toString()
    ];
    return TheoryMiniLessonNode(
      id: json['id']?.toString() ?? '',
      refId: json['refId']?.toString(),
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      tags: tags,
      targetStreet: json['targetStreet']?.toString(),
      stage: json['stage']?.toString(),
      nextIds: nextIds,
      linkedPackIds: linked,
      recoveredFromMistake: json['recoveredFromMistake'] as bool? ?? false,
      autoContent: json['autoContent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (refId != null) 'refId': refId,
        'title': title,
        'content': content,
        if (tags.isNotEmpty) 'tags': tags,
        if (targetStreet != null) 'targetStreet': targetStreet,
        if (stage != null) 'stage': stage,
        if (nextIds.isNotEmpty) 'nextIds': nextIds,
        if (linkedPackIds.isNotEmpty) 'linkedPackIds': linkedPackIds,
        if (recoveredFromMistake) 'recoveredFromMistake': recoveredFromMistake,
        if (autoContent) 'autoContent': autoContent,
      };
}
