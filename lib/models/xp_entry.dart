import 'package:uuid/uuid.dart';

class XPEntry {
  final String id;
  final DateTime date;
  final int xp;
  final String source;
  final int streak;

  XPEntry({
    String? id,
    required this.date,
    required this.xp,
    required this.source,
    required this.streak,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'xp': xp,
        'source': source,
        'streak': streak,
      };

  factory XPEntry.fromJson(Map<String, dynamic> json) => XPEntry(
        id: json['id'] as String?,
        date:
            DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        xp: json['xp'] as int? ?? 0,
        source: json['source'] as String? ?? '',
        streak: json['streak'] as int? ?? 0,
      );
}
