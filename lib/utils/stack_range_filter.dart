class StackRangeFilter {
  final int _min;
  final int _max;

  const StackRangeFilter({required int min, required int max})
      : _min = min,
        _max = max;

  int get min => _min;
  int get max => _max;

  bool contains(int value) => value >= _min && value <= _max;

  StackRangeFilter copyWith({int? min, int? max}) =>
      StackRangeFilter(min: min ?? _min, max: max ?? _max);
}
