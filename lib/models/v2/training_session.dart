import 'package:uuid/uuid.dart';
import 'training_pack_template.dart';

class TrainingSession {
  final String id;
  final String templateId;
  DateTime startedAt;
  DateTime? completedAt;
  int index;
  final Map<String, bool> results;
  final bool authorPreview;
  bool get isCompleted => completedAt != null;

  TrainingSession({
    required this.id,
    required this.templateId,
    DateTime? startedAt,
    this.completedAt,
    this.index = 0,
    Map<String, bool>? results,
    this.authorPreview = false,
  }) : startedAt = startedAt ?? DateTime.now(),
       results = results ?? {};

  factory TrainingSession.fromJson(Map<String, dynamic> j) => TrainingSession(
    id: j['id'] as String? ?? '',
    templateId: j['templateId'] as String? ?? '',
    startedAt:
        DateTime.tryParse(j['startedAt'] as String? ?? '') ?? DateTime.now(),
    completedAt: j['completedAt'] != null
        ? DateTime.tryParse(j['completedAt'])
        : null,
    index: j['index'] as int? ?? 0,
    results: j['results'] != null
        ? Map<String, bool>.from(j['results'] as Map)
        : {},
    authorPreview: j['authorPreview'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'templateId': templateId,
    'startedAt': startedAt.toIso8601String(),
    if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
    'index': index,
    if (results.isNotEmpty) 'results': results,
    if (authorPreview) 'authorPreview': true,
  };

  factory TrainingSession.fromTemplate(
    TrainingPackTemplate template, {
    bool authorPreview = false,
  }) => TrainingSession(
    id: const Uuid().v4(),
    templateId: template.id,
    authorPreview: authorPreview,
  );
}
