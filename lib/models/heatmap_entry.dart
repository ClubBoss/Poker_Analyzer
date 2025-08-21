class HeatmapEntry {
  final DateTime date;
  final int count;

  const HeatmapEntry({required this.date, required this.count});

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'count': count,
  };

  factory HeatmapEntry.fromJson(Map<String, dynamic> json) => HeatmapEntry(
    date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    count: (json['count'] as num?)?.toInt() ?? 0,
  );
}
