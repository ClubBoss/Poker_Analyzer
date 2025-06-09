import 'saved_hand.dart';

class TrainingPack {
  final String name;
  final String description;
  final String category;
  final List<SavedHand> hands;

  TrainingPack({
    required this.name,
    required this.description,
    this.category = 'Uncategorized',
    required this.hands,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'category': category,
        'hands': [for (final h in hands) h.toJson()],
      };

  factory TrainingPack.fromJson(Map<String, dynamic> json) => TrainingPack(
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? 'Uncategorized',
        hands: [
          for (final h in (json['hands'] as List? ?? []))
            SavedHand.fromJson(h as Map<String, dynamic>)
        ],
      );
}
