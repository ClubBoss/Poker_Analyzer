class NodeVisit {
  final String nodeId;
  final DateTime firstSeen;
  final DateTime? completedAt;

  const NodeVisit({
    required this.nodeId,
    required this.firstSeen,
    this.completedAt,
  });

  NodeVisit copyWith({DateTime? completedAt}) => NodeVisit(
    nodeId: nodeId,
    firstSeen: firstSeen,
    completedAt: completedAt ?? this.completedAt,
  );

  Map<String, dynamic> toJson() => {
    'nodeId': nodeId,
    'firstSeen': firstSeen.toIso8601String(),
    if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
  };

  factory NodeVisit.fromJson(Map<String, dynamic> json) => NodeVisit(
    nodeId: json['nodeId']?.toString() ?? '',
    firstSeen:
        DateTime.tryParse(json['firstSeen']?.toString() ?? '') ??
        DateTime.now(),
    completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? ''),
  );
}
