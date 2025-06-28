class EvalResult {
  final bool isError;
  final String? reason;
  final double score;

  EvalResult({required this.isError, this.reason, required this.score});
}
