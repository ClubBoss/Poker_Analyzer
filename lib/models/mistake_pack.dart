import 'package:uuid/uuid.dart';

class MistakePack {
  final String id;
  final String templateId;
  final List<String> spotIds;
  final DateTime createdAt;
  final String note;

  MistakePack({
    String? id,
    required this.templateId,
    List<String>? spotIds,
    DateTime? createdAt,
    this.note = '',
  })  : id = id ?? const Uuid().v4(),
        spotIds = spotIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'templateId': templateId,
        'spotIds': spotIds,
        'createdAt': createdAt.toIso8601String(),
        if (note.isNotEmpty) 'note': note,
      };

  factory MistakePack.fromJson(Map<String, dynamic> j) => MistakePack(
        id: j['id'] as String?,
        templateId: j['templateId'] as String? ?? '',
        spotIds: [for (final s in (j['spotIds'] as List? ?? [])) s as String],
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
        note: j['note'] as String? ?? '',
      );
}
