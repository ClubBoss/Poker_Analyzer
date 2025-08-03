class StackRangeFilter {
  final int? _min;
  final int? _max;

  StackRangeFilter(String? raw) : _min = _parseMin(raw), _max = _parseMax(raw);

  static int? _parseMin(String? raw) {
    if (raw == null) return null;
    if (raw.endsWith('+')) {
      return int.tryParse(raw.substring(0, raw.length - 1)) ?? 0;
    }
    final parts = raw.split('-');
    if (parts.length == 2) {
      return int.tryParse(parts[0]) ?? 0;
    }
    return null;
  }

  static int? _parseMax(String? raw) {
    if (raw == null) return null;
    if (raw.endsWith('+')) return null;
    final parts = raw.split('-');
    if (parts.length == 2) {
      return int.tryParse(parts[1]) ?? 0;
    }
    return null;
  }

  bool matches(int stack) {
    final min = _min;
    final max = _max;
    if (min != null && stack < min) return false;
    if (max != null && stack > max) return false;
    return true;
  }
}
