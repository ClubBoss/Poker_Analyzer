class MixedDrillStat {
  final DateTime date;
  final int total;
  final int correct;
  final List<String> tags;
  final String street;

  MixedDrillStat({
    required this.date,
    required this.total,
    required this.correct,
    required this.tags,
    required this.street,
  });

  double get accuracy => total == 0 ? 0 : correct * 100 / total;

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'total': total,
    'correct': correct,
    if (tags.isNotEmpty) 'tags': tags,
    'street': street,
  };

  factory MixedDrillStat.fromJson(Map<String, dynamic> j) => MixedDrillStat(
    date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
    total: j['total'] as int? ?? 0,
    correct: j['correct'] as int? ?? 0,
    tags: [for (final t in (j['tags'] as List? ?? [])) t as String],
    street: j['street'] as String? ?? 'any',
  );
}
