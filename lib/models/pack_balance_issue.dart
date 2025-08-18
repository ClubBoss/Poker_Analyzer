class PackBalanceIssue {
  final String type;
  final String description;
  final int severity;
  const PackBalanceIssue({
    required this.type,
    required this.description,
    required this.severity,
  });
  Map<String, dynamic> toJson() => {
    'type': type,
    'description': description,
    'severity': severity,
  };
  factory PackBalanceIssue.fromJson(Map<String, dynamic> j) => PackBalanceIssue(
    type: j['type']?.toString() ?? '',
    description: j['description']?.toString() ?? '',
    severity: (j['severity'] as num?)?.toInt() ?? 0,
  );
}
