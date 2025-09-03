// ASCII-only; no external deps beyond dart:core

class LiveContext {
  final bool hasStraddle;
  final bool bombAnte;
  final int multiLimpers; // 0..9
  final bool announceRequired;
  final String rakeType; // "", "time", "drop"
  final int avgStackBb; // >=0
  final String tableSpeed; // "", "slow", "normal", "fast"

  const LiveContext({
    required this.hasStraddle,
    required this.bombAnte,
    required this.multiLimpers,
    required this.announceRequired,
    required this.rakeType,
    required this.avgStackBb,
    required this.tableSpeed,
  }) : assert(multiLimpers >= 0 && multiLimpers <= 9),
       assert(avgStackBb >= 0),
       assert(rakeType == '' || rakeType == 'time' || rakeType == 'drop'),
       assert(
         tableSpeed == '' ||
             tableSpeed == 'slow' ||
             tableSpeed == 'normal' ||
             tableSpeed == 'fast',
       );

  const LiveContext.off()
    : hasStraddle = false,
      bombAnte = false,
      multiLimpers = 0,
      announceRequired = false,
      rakeType = '',
      avgStackBb = 0,
      tableSpeed = '';

  LiveContext copyWith({
    bool? hasStraddle,
    bool? bombAnte,
    int? multiLimpers,
    bool? announceRequired,
    String? rakeType,
    int? avgStackBb,
    String? tableSpeed,
  }) {
    return LiveContext(
      hasStraddle: hasStraddle ?? this.hasStraddle,
      bombAnte: bombAnte ?? this.bombAnte,
      multiLimpers: multiLimpers ?? this.multiLimpers,
      announceRequired: announceRequired ?? this.announceRequired,
      rakeType: rakeType ?? this.rakeType,
      avgStackBb: avgStackBb ?? this.avgStackBb,
      tableSpeed: tableSpeed ?? this.tableSpeed,
    );
  }

  bool get isOff =>
      hasStraddle == false &&
      bombAnte == false &&
      multiLimpers == 0 &&
      announceRequired == false &&
      rakeType.isEmpty &&
      avgStackBb == 0 &&
      tableSpeed.isEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiveContext &&
        other.hasStraddle == hasStraddle &&
        other.bombAnte == bombAnte &&
        other.multiLimpers == multiLimpers &&
        other.announceRequired == announceRequired &&
        other.rakeType == rakeType &&
        other.avgStackBb == avgStackBb &&
        other.tableSpeed == tableSpeed;
  }

  @override
  int get hashCode => Object.hash(
    hasStraddle,
    bombAnte,
    multiLimpers,
    announceRequired,
    rakeType,
    avgStackBb,
    tableSpeed,
  );

  @override
  String toString() {
    return 'LiveContext(hasStraddle: $hasStraddle, '
        'bombAnte: $bombAnte, '
        'multiLimpers: $multiLimpers, '
        'announceRequired: $announceRequired, '
        'rakeType: $rakeType, '
        'avgStackBb: $avgStackBb, '
        'tableSpeed: $tableSpeed)';
  }
}
