import 'dart:convert';

class UserGoal {
  final String id;
  final String title;
  final String type;
  final int target;
  final int base;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? tag;
  final double? targetAccuracy;

  const UserGoal({
    required this.id,
    required this.title,
    required this.type,
    required this.target,
    required this.base,
    required this.createdAt,
    this.completedAt,
    this.tag,
    this.targetAccuracy,
  });

  bool get completed => completedAt != null;

  UserGoal copyWith({DateTime? completedAt}) => UserGoal(
        id: id,
        title: title,
        type: type,
        target: target,
        base: base,
        createdAt: createdAt,
        completedAt: completedAt,
        tag: tag,
        targetAccuracy: targetAccuracy,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'target': target,
        'base': base,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        if (tag != null) 'tag': tag,
        if (targetAccuracy != null) 'targetAccuracy': targetAccuracy,
      };

  factory UserGoal.fromJson(Map<String, dynamic> json) => UserGoal(
        id: json['id'] as String,
        title: json['title'] as String,
        type: json['type'] as String,
        target: json['target'] as int,
        base: json['base'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        tag: json['tag'] as String?,
        targetAccuracy: (json['targetAccuracy'] as num?)?.toDouble(),
      );

  static String encode(List<UserGoal> list) =>
      jsonEncode([for (final g in list) g.toJson()]);

  static List<UserGoal> decode(String raw) {
    final data = jsonDecode(raw) as List;
    return [
      for (final e in data)
        UserGoal.fromJson(Map<String, dynamic>.from(e as Map))
    ];
  }
}
