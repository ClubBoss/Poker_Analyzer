class DecayForecastAlert {
  final String tag;
  final int daysToCritical; // 7 or 14
  final double projectedDecay;

  const DecayForecastAlert({
    required this.tag,
    required this.daysToCritical,
    required this.projectedDecay,
  });
}
