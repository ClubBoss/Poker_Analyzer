import '../models/theory_cluster_summary.dart';

class WeakClusterInfo {
  final TheoryClusterSummary cluster;
  final double coverage;
  final double score;

  const WeakClusterInfo({
    required this.cluster,
    required this.coverage,
    required this.score,
  });
}
