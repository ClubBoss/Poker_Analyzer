class TheoryUsageIssue {
  final String id;
  final String title;
  final String reason;

  const TheoryUsageIssue({
    required this.id,
    required this.title,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'reason': reason};

  factory TheoryUsageIssue.fromJson(Map<String, dynamic> json) =>
      TheoryUsageIssue(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        reason: json['reason']?.toString() ?? '',
      );
}
