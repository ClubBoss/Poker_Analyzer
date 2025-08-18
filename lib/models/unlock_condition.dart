class UnlockCondition {
  final String? dependsOn;
  final int? minAccuracy;

  const UnlockCondition({this.dependsOn, this.minAccuracy});

  factory UnlockCondition.fromJson(Map<String, dynamic> json) {
    return UnlockCondition(
      dependsOn: json['dependsOn'] as String?,
      minAccuracy: (json['minAccuracy'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (dependsOn != null) 'dependsOn': dependsOn,
    if (minAccuracy != null) 'minAccuracy': minAccuracy,
  };

  factory UnlockCondition.fromYaml(Map yaml) {
    final map = <String, dynamic>{};
    yaml.forEach((k, v) => map[k.toString()] = v);
    return UnlockCondition.fromJson(map);
  }
}
