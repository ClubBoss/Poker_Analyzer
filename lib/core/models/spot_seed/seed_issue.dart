/// Represents an issue found during seed validation.
class SeedIssue {
  final String code;
  final String severity; // 'error' or 'warn'
  final String message;
  final List<String> path;

  const SeedIssue({
    required this.code,
    required this.severity,
    required this.message,
    this.path = const <String>[],
  });
}
