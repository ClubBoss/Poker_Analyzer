class BoosterSummary {
  final String id;
  final double avgDeltaEV;
  final int totalSpots;
  final int injections;

  BoosterSummary({
    required this.id,
    required this.avgDeltaEV,
    required this.totalSpots,
    required this.injections,
  });

  bool get isEffective => avgDeltaEV > 0.01;

  Map<String, dynamic> toJson() => {
        'id': id,
        'avgDeltaEV': avgDeltaEV,
        'totalSpots': totalSpots,
        'injections': injections,
      };

  factory BoosterSummary.fromJson(Map<String, dynamic> json) => BoosterSummary(
        id: json['id'] as String? ?? '',
        avgDeltaEV: (json['avgDeltaEV'] as num?)?.toDouble() ?? 0.0,
        totalSpots: json['totalSpots'] as int? ?? 0,
        injections: json['injections'] as int? ?? 0,
      );
}
