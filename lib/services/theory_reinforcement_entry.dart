import 'package:json_annotation/json_annotation.dart';

part 'theory_reinforcement_entry.g.dart';

@JsonSerializable()
class TheoryReinforcementEntry {
  final int level;
  final DateTime next;

  const TheoryReinforcementEntry({required this.level, required this.next});

  factory TheoryReinforcementEntry.fromJson(Map<String, dynamic> json) =>
      _$TheoryReinforcementEntryFromJson(json);

  Map<String, dynamic> toJson() => _$TheoryReinforcementEntryToJson(this);
}
