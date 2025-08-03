class StackRangeFilter {
  final int? _min;
  final int? _max;

  StackRangeFilter(String? raw)
      : (_min, _max) = raw == null ? (null, null) : _parseRange(raw);

  static (int?, int?) _parseRange(String raw) {
    if (raw.endsWith('+')) {
      return (int.tryParse(raw.substring(0, raw.length - 1)) ?? 0, null);
    }
    final parts = raw.split('-');
    if (parts.length == 2) {
      return (
        int.tryParse(parts[0]) ?? 0,
        int.tryParse(parts[1]) ?? 0,
      );
    }
    return (null, null);
  }

  bool matches(int stack) {
    final min = _min;
    final max = _max;
    if (min != null && stack < min) return false;
    if (max != null && stack > max) return false;
    return true;
  }
}
