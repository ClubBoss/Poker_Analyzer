class XPEntry {
  final DateTime date;
  final int xp;
  final String source;
  final int streak;

  XPEntry({
    required this.date,
    required this.xp,
    required this.source,
    required this.streak,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'xp': xp,
        'source': source,
        'streak': streak,
      };

  factory XPEntry.fromJson(Map<String, dynamic> json) => XPEntry(
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        xp: json['xp'] as int? ?? 0,
        source: json['source'] as String? ?? '',
        streak: json['streak'] as int? ?? 0,
      );
}

