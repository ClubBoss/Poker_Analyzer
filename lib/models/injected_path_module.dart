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
  final String status;
  final Map<String, dynamic> metrics;
  final Map<String, int>? itemsDurations;

  const InjectedPathModule({
    required this.moduleId,
    required this.clusterId,
    required this.themeName,
    required this.theoryIds,
    required this.boosterPackIds,
    required this.assessmentPackId,
    required this.createdAt,
    required this.triggerReason,
    this.status = 'pending',
    Map<String, dynamic>? metrics,
    this.itemsDurations,
  }) : metrics = metrics ?? const {};

  InjectedPathModule copyWith({
    String? status,
    Map<String, dynamic>? metrics,
    Map<String, int>? itemsDurations,
  }) {
    return InjectedPathModule(
      moduleId: moduleId,
      clusterId: clusterId,
      themeName: themeName,
      theoryIds: theoryIds,
      boosterPackIds: boosterPackIds,
      assessmentPackId: assessmentPackId,
      createdAt: createdAt,
      triggerReason: triggerReason,
      status: status ?? this.status,
      metrics: metrics ?? Map<String, dynamic>.from(this.metrics),
      itemsDurations: itemsDurations ?? this.itemsDurations,
    );
  }

  Map<String, dynamic> toJson() => {
    'moduleId': moduleId,
    'clusterId': clusterId,
    'themeName': themeName,
    'theoryIds': theoryIds,
    'boosterPackIds': boosterPackIds,
    'assessmentPackId': assessmentPackId,
    'createdAt': createdAt.toIso8601String(),
    'triggerReason': triggerReason,
    'status': status,
    'metrics': metrics,
    if (itemsDurations != null) 'itemsDurations': itemsDurations,
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
        status: json['status'] as String? ?? 'pending',
        metrics: (json['metrics'] as Map?)?.cast<String, dynamic>() ?? const {},
        itemsDurations: (json['itemsDurations'] as Map?)?.map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        ),
      );

  @override
  String toString() => jsonEncode(toJson());
}
