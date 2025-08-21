import 'unlock_condition.dart';

class SubStageModel {
  final String id;
  final String packId;
  final String title;
  final String description;
  final int requiredHands;
  @Deprecated('Use requiredHands instead')
  int get minHands => requiredHands;
  final double requiredAccuracy;
  final List<String> objectives;
  final UnlockCondition? unlockCondition;

  const SubStageModel({
    required this.id,
    required this.packId,
    required this.title,
    this.description = '',
    int? requiredHands,
    int minHands = 0,
    this.requiredAccuracy = 0,
    this.objectives = const [],
    this.unlockCondition,
  }) : requiredHands = requiredHands ?? minHands;

  factory SubStageModel.fromJson(Map<String, dynamic> json) {
    return SubStageModel(
      id: json['id'] as String? ?? '',
      packId: json['packId'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      requiredHands: (json['requiredHands'] as num?)?.toInt() ??
          (json['minHands'] as num?)?.toInt() ??
          0,
      requiredAccuracy: (json['requiredAccuracy'] as num?)?.toDouble() ?? 0.0,
      objectives: [
        for (final o in (json['objectives'] as List? ?? [])) o.toString(),
      ],
      unlockCondition: json['unlockCondition'] is Map
          ? UnlockCondition.fromJson(
              Map<String, dynamic>.from(json['unlockCondition'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'packId': packId,
        'title': title,
        if (description.isNotEmpty) 'description': description,
        if (requiredHands > 0) 'requiredHands': requiredHands,
        if (requiredAccuracy > 0) 'requiredAccuracy': requiredAccuracy,
        if (objectives.isNotEmpty) 'objectives': objectives,
        if (unlockCondition != null)
          'unlockCondition': unlockCondition!.toJson(),
      };

  factory SubStageModel.fromYaml(Map yaml) {
    final map = <String, dynamic>{};
    yaml.forEach((k, v) => map[k.toString()] = v);
    return SubStageModel.fromJson(map);
  }
}
