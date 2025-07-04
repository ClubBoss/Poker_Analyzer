class FocusGoal {
  final String label;
  final int weight;
  const FocusGoal(this.label, [this.weight = 100]);

  factory FocusGoal.fromString(String s) {
    final parts = s.split(':');
    final label = parts.first.trim();
    final weight = parts.length > 1 ? int.tryParse(parts[1]) ?? 100 : 100;
    return FocusGoal(label, weight);
  }

  factory FocusGoal.fromJson(dynamic json) {
    if (json is String) return FocusGoal.fromString(json);
    if (json is Map) {
      return FocusGoal(
        json['label'] as String? ?? '',
        (json['weight'] as num?)?.toInt() ?? 100,
      );
    }
    return FocusGoal(json.toString());
  }

  dynamic toJson() => weight == 100 ? label : '$label:$weight';

  @override
  String toString() => weight == 100 ? label : '$label:$weight';
}
