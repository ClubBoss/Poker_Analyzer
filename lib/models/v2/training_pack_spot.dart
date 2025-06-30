import 'package:collection/collection.dart';

class TrainingPackSpot {
  final String id;
  String title;
  String note;
  List<String> tags;

  TrainingPackSpot({
    required this.id,
    this.title = '',
    this.note = '',
    List<String>? tags,
  }) : tags = tags ?? [];

  TrainingPackSpot copyWith({
    String? id,
    String? title,
    String? note,
    List<String>? tags,
  }) =>
      TrainingPackSpot(
        id: id ?? this.id,
        title: title ?? this.title,
        note: note ?? this.note,
        tags: tags ?? List<String>.from(this.tags),
      );

  factory TrainingPackSpot.fromJson(Map<String, dynamic> j) => TrainingPackSpot(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        note: j['note'] as String? ?? '',
        tags: [for (final t in (j['tags'] as List? ?? [])) t as String],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        if (tags.isNotEmpty) 'tags': tags,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingPackSpot &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          note == other.note &&
          const ListEquality().equals(tags, other.tags);

  @override
  int get hashCode => Object.hash(id, title, note, const ListEquality().hash(tags));
}
