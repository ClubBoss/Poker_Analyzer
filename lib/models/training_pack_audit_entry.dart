import 'dart:convert';

class TrainingPackAuditEntry {
  final String packId;
  final DateTime timestamp;
  final String userId;
  final List<String> changedFields;
  final Map<String, dynamic> diffSnapshot;

  TrainingPackAuditEntry({
    required this.packId,
    required this.timestamp,
    required this.userId,
    required this.changedFields,
    Map<String, dynamic>? diffSnapshot,
  }) : diffSnapshot = diffSnapshot ?? const {};

  Map<String, dynamic> toJson() => {
        'packId': packId,
        'timestamp': timestamp.toIso8601String(),
        'userId': userId,
        'changedFields': changedFields,
        'diffSnapshot': diffSnapshot,
      };

  factory TrainingPackAuditEntry.fromJson(Map<String, dynamic> json) {
    return TrainingPackAuditEntry(
      packId: json['packId']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      userId: json['userId']?.toString() ?? '',
      changedFields:
          (json['changedFields'] as List?)?.map((e) => e.toString()).toList() ??
              <String>[],
      diffSnapshot: json['diffSnapshot'] is Map
          ? Map<String, dynamic>.from(json['diffSnapshot'] as Map)
          : <String, dynamic>{},
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}
