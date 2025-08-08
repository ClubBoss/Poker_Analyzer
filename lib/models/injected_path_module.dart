import 'dart:convert';

/// Model representing an automatically injected learning path module.
class InjectedPathModule {
  final String moduleId;
  final String clusterId;
  final String themeName;
  final List<String> theoryIds;
  final List<String> boosterPackIds;
  final String assessmentPackId;
  final DateTime createdAt;
  final String triggerReason;

  const InjectedPathModule({
    required this.moduleId,
    required this.clusterId,
    required this.themeName,
    required this.theoryIds,
    required this.boosterPackIds,
    required this.assessmentPackId,
    required this.createdAt,
    required this.triggerReason,
  });

  Map<String, dynamic> toJson() => {
        'moduleId': moduleId,
        'clusterId': clusterId,
        'themeName': themeName,
        'theoryIds': theoryIds,
        'boosterPackIds': boosterPackIds,
        'assessmentPackId': assessmentPackId,
        'createdAt': createdAt.toIso8601String(),
        'triggerReason': triggerReason,
      };

  static InjectedPathModule fromJson(Map<String, dynamic> json) =>
      InjectedPathModule(
        moduleId: json['moduleId'] as String,
        clusterId: json['clusterId'] as String,
        themeName: json['themeName'] as String,
        theoryIds: (json['theoryIds'] as List).cast<String>(),
        boosterPackIds: (json['boosterPackIds'] as List).cast<String>(),
        assessmentPackId: json['assessmentPackId'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        triggerReason: json['triggerReason'] as String,
      );

  @override
  String toString() => jsonEncode(toJson());
}
