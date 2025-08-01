class TagDecayForecast {
  final String tag;
  final double current;
  final double in7days;
  final double in14days;
  final double in30days;

  const TagDecayForecast({
    required this.tag,
    required this.current,
    required this.in7days,
    required this.in14days,
    required this.in30days,
  });
}
