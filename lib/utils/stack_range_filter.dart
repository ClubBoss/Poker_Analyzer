class StackRangeFilter {
  final int? _min;
  final int? _max;

  factory StackRangeFilter(String? raw) {
    final parsed = raw == null ? (null, null) : _parseRange(raw);
    return StackRangeFilter._(parsed.$1, parsed.$2);
  }

  const StackRangeFilter._(this._min, this._max);

  static (int?, int?) _parseRange(String raw) {
    if (raw.endsWith('+')) {
      final min = int.tryParse(raw.substring(0, raw.length - 1));
      if (min == null || min < 0) return (null, null);
      return (min, null);
    }
    final parts = raw.split('-');
    if (parts.length == 2) {
      final min = int.tryParse(parts[0]);
      final max = int.tryParse(parts[1]);
      if (min == null || max == null) return (null, null);
      if (min < 0 || max < 0 || min > max) return (null, null);
      return (min, max);
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
