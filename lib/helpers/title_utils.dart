String normalizeSpotTitle(String title) {
  final words = title.trim().split(RegExp(r'\s+'));
  final result = <String>[];
  for (final w in words) {
    if (w.isEmpty) continue;
    final lower = w.toLowerCase();
    if (lower == 'vs') {
      result.add('vs');
    } else if (w.length <= 2) {
      result.add(w.toUpperCase());
    } else {
      result.add(lower[0].toUpperCase() + lower.substring(1));
    }
  }
  return result.join(' ');
}
