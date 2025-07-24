import 'package:json2yaml/json2yaml.dart';

/// Input model for sub-stage generation.
class SubStageTemplateInput {
  final String id;
  final String packId;
  final String title;
  final String description;
  final int minHands;
  final double requiredAccuracy;
  final List<String> objectives;
  final UnlockConditionInput? unlockCondition;

  const SubStageTemplateInput({
    required this.id,
    required this.packId,
    required this.title,
    this.description = '',
    this.minHands = 0,
    this.requiredAccuracy = 0,
    this.objectives = const [],
    this.unlockCondition,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'packId': packId,
        'title': title,
        if (description.isNotEmpty) 'description': description,
        if (minHands > 0) 'minHands': minHands,
        if (requiredAccuracy > 0) 'requiredAccuracy': requiredAccuracy,
        if (objectives.isNotEmpty) 'objectives': objectives,
        if (unlockCondition != null)
          'unlockCondition': unlockCondition!.toMap(),
      };
}

/// Input model for unlock conditions.
class UnlockConditionInput {
  final String? dependsOn;
  final int? minAccuracy;

  const UnlockConditionInput({this.dependsOn, this.minAccuracy});

  Map<String, dynamic> toMap() => {
        if (dependsOn != null) 'dependsOn': dependsOn,
        if (minAccuracy != null) 'minAccuracy': minAccuracy,
      };
}

/// Generates YAML for [LearningPathStageModel] templates.
class LearningPathStageTemplateGenerator {
  int _order = 0;
  String? _lastId;

  /// Resets internal counters.
  void reset() {
    _order = 0;
    _lastId = null;
  }

  List<String> _autoTags(String packId) {
    final tokens = packId.split(RegExp(r'[\-_]'));
    return tokens.toSet().toList();
  }

  /// Generates YAML for a single stage.
  String generateStageYaml({
    required String id,
    required String title,
    required String packId,
    String description = '',
    double requiredAccuracy = 80,
    int minHands = 10,
    List<SubStageTemplateInput> subStages = const [],
    UnlockConditionInput? unlockCondition,
    List<String>? objectives,
    List<String>? tags,
  }) {
    _order += 1;
    final map = <String, dynamic>{
      'id': id,
      'title': title,
      if (description.isNotEmpty) 'description': description,
      'packId': packId,
      'requiredAccuracy': requiredAccuracy,
      'minHands': minHands,
      'order': _order,
    };

    map['tags'] = tags == null || tags.isEmpty ? _autoTags(packId) : tags;
    if (_lastId != null) {
      map['unlockAfter'] = [_lastId];
    }
    if (unlockCondition != null) {
      map['unlockCondition'] = unlockCondition.toMap();
    }
    if (objectives != null && objectives.isNotEmpty) {
      map['objectives'] = objectives;
    }
    if (subStages.isNotEmpty) {
      map['subStages'] = [for (final s in subStages) s.toMap()];
    }

    final yamlOut = json2yaml(map, yamlStyle: YamlStyle.pubspecYaml);
    _lastId = id;
    return yamlOut;
  }
}
