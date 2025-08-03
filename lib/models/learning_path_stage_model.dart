import 'dart:convert';

import 'unlock_condition.dart';
import 'sub_stage_model.dart';
import 'stage_type.dart';

class LearningPathStageModel {
  final String id;
  final String title;
  final String description;
  final StageType type;
  final String packId;
  final String? theoryPackId;
  final List<String>? boosterTheoryPackIds;
  final double requiredAccuracy;
  final int requiredHands;
  @Deprecated('Use requiredHands instead')
  int get minHands => requiredHands;
  final List<SubStageModel> subStages;
  final List<String> unlocks;
  final List<String> unlockAfter;
  final List<String> tags;
  final List<String> objectives;
  final int order;
  final bool isOptional;
  final UnlockCondition? unlockCondition;

  const LearningPathStageModel({
    required this.id,
    required this.title,
    required this.description,
    required this.packId,
    this.theoryPackId,
    this.boosterTheoryPackIds,
    required this.requiredAccuracy,
    int? requiredHands,
    int minHands = 0,
    List<SubStageModel>? subStages,
    List<String>? unlocks,
    List<String>? tags,
    List<String>? unlockAfter,
    List<String>? objectives,
    this.order = 0,
    this.isOptional = false,
    this.unlockCondition,
    this.type = StageType.practice,
  })  : requiredHands = requiredHands ?? minHands,
        unlocks = unlocks ?? const [],
        unlockAfter = unlockAfter ?? const [],
        tags = tags ?? const [],
        objectives = objectives ?? const [],
        subStages = subStages ?? const [];

  factory LearningPathStageModel.fromJson(Map<String, dynamic> json) {
    return LearningPathStageModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      packId: json['packId'] as String? ?? '',
      type: _parseType(json['type']),
      theoryPackId: json['theoryPackId'] as String?,
      boosterTheoryPackIds: [
        for (final b in (json['boosterTheoryPackIds'] as List? ?? []))
          b.toString()
      ],
      requiredAccuracy: (json['requiredAccuracy'] as num?)?.toDouble() ?? 0.0,
      requiredHands: (json['requiredHands'] as num?)?.toInt() ??
          (json['minHands'] as num?)?.toInt() ??
          0,
      unlocks: [for (final u in (json['unlocks'] as List? ?? [])) u.toString()],
      unlockAfter: [
        for (final u in (json['unlockAfter'] as List? ?? [])) u.toString(),
      ],
      tags: [for (final t in (json['tags'] as List? ?? [])) t.toString()],
      objectives: [
        for (final o in (json['objectives'] as List? ?? [])) o.toString()
      ],
      order: (json['order'] as num?)?.toInt() ?? 0,
      isOptional: json['isOptional'] as bool? ?? false,
      unlockCondition: json['unlockCondition'] is Map
          ? UnlockCondition.fromJson(
              Map<String, dynamic>.from(json['unlockCondition'] as Map),
            )
          : null,
      subStages: [
        for (final s in (json['subStages'] as List? ?? []))
          SubStageModel.fromJson(Map<String, dynamic>.from(s)),
      ],
    );
  }

  static StageType _parseType(dynamic value) {
    final s = value?.toString();
    switch (s) {
      case 'theory':
        return StageType.theory;
      case 'booster':
        return StageType.booster;
    }
    return StageType.practice;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'packId': packId,
        'type': type.name,
        if (theoryPackId != null) 'theoryPackId': theoryPackId,
        if (boosterTheoryPackIds != null && boosterTheoryPackIds!.isNotEmpty)
          'boosterTheoryPackIds': boosterTheoryPackIds,
        'requiredAccuracy': requiredAccuracy,
        'requiredHands': requiredHands,
        if (unlocks.isNotEmpty) 'unlocks': unlocks,
        if (unlockAfter.isNotEmpty) 'unlockAfter': unlockAfter,
        if (tags.isNotEmpty) 'tags': tags,
        if (objectives.isNotEmpty) 'objectives': objectives,
        'order': order,
        if (isOptional) 'isOptional': true,
        if (unlockCondition != null)
          'unlockCondition': unlockCondition!.toJson(),
        if (subStages.isNotEmpty)
          'subStages': [for (final s in subStages) s.toJson()],
      };

  factory LearningPathStageModel.fromYaml(Map yaml) {
    final map = jsonDecode(jsonEncode(yaml)) as Map<String, dynamic>;
    return LearningPathStageModel.fromJson(map);
  }
}
