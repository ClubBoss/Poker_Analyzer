class TagDecayEntry {
  final String tag;
  final double decay;
  final int boosters;

  const TagDecayEntry({
    required this.tag,
    required this.decay,
    this.boosters = 0,
  });
}
