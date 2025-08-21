class BoosterEffectLog {
  final String id;
  final String type;
  final double deltaEV;
  final int spotsTracked;
  final DateTime timestamp;

  BoosterEffectLog({
    required this.id,
    required this.type,
    required this.deltaEV,
    required this.spotsTracked,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'deltaEV': deltaEV,
    'spotsTracked': spotsTracked,
    'timestamp': timestamp.toIso8601String(),
  };

  factory BoosterEffectLog.fromJson(Map<String, dynamic> json) =>
      BoosterEffectLog(
        id: json['id'] as String? ?? '',
        type: json['type'] as String? ?? '',
        deltaEV: (json['deltaEV'] as num?)?.toDouble() ?? 0.0,
        spotsTracked: json['spotsTracked'] as int? ?? 0,
        timestamp:
            DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
      );
}
