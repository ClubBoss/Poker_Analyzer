class SpotSimilarityResult {
  final String idA;
  final String idB;
  final double similarity;

  const SpotSimilarityResult({
    required this.idA,
    required this.idB,
    required this.similarity,
  });

  Map<String, dynamic> toJson() => {
    'idA': idA,
    'idB': idB,
    'similarity': similarity,
  };

  factory SpotSimilarityResult.fromJson(Map<String, dynamic> json) =>
      SpotSimilarityResult(
        idA: json['idA'] as String? ?? '',
        idB: json['idB'] as String? ?? '',
        similarity: (json['similarity'] as num?)?.toDouble() ?? 0.0,
      );
}
