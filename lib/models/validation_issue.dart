class ValidationIssue {
  final String type;
  final String message;
  final int? line;
  const ValidationIssue({required this.type, required this.message, this.line});
  Map<String, dynamic> toJson() => {
        'type': type,
        'message': message,
        if (line != null) 'line': line,
      };
  factory ValidationIssue.fromJson(Map<String, dynamic> j) => ValidationIssue(
        type: j['type']?.toString() ?? '',
        message: j['message']?.toString() ?? '',
        line: (j['line'] as num?)?.toInt(),
      );
}
