import 'saved_hand.dart';

class DrillSessionResult {
  final DateTime date;
  final String position;
  final String street;
  final int total;
  final int correct;
  final List<SavedHand> hands;
  final String? type;
  final bool? completed;
  final int? handsSeen;

  DrillSessionResult({
    required this.date,
    required this.position,
    required this.street,
    required this.total,
    required this.correct,
    required this.hands,
    this.type,
    this.completed,
    this.handsSeen,
  });

  double get accuracy => total == 0 ? 0 : correct / total;

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'position': position,
    'street': street,
    'total': total,
    'correct': correct,
    'hands': [for (final h in hands) h.toJson()],
    if (type != null) 'type': type,
    if (completed != null) 'completed': completed,
    if (handsSeen != null) 'handsSeen': handsSeen,
  };

  factory DrillSessionResult.fromJson(Map<String, dynamic> json) =>
      DrillSessionResult(
        date:
            DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        position: json['position'] as String? ?? '',
        street: json['street'] as String? ?? '',
        total: json['total'] as int? ?? 0,
        correct: json['correct'] as int? ?? 0,
        hands: [
          for (final h in (json['hands'] as List? ?? []))
            SavedHand.fromJson(Map<String, dynamic>.from(h as Map)),
        ],
        type: json['type'] as String?,
        completed: json['completed'] as bool?,
        handsSeen: json['handsSeen'] as int?,
      );
}
