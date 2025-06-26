import 'saved_hand.dart';

class TrainingPackTemplate {
  final String id;
  final String name;
  final String gameType;
  final String description;
  final List<SavedHand> hands;
  final String version;
  final String author;
  final bool isBuiltIn;

  TrainingPackTemplate({
    required this.id,
    required this.name,
    required this.gameType,
    required this.description,
    required this.hands,
    this.version = '1.0',
    this.author = '',
    this.isBuiltIn = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'gameType': gameType,
        'description': description,
        'hands': [for (final h in hands) h.toJson()],
        'version': version,
        'author': author,
        'isBuiltIn': isBuiltIn,
      };

  factory TrainingPackTemplate.fromJson(Map<String, dynamic> json) {
    return TrainingPackTemplate(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      gameType: json['gameType'] as String? ?? 'Cash Game',
      description: json['description'] as String? ?? '',
      hands: [
        for (final h in (json['hands'] as List? ?? []))
          SavedHand.fromJson(Map<String, dynamic>.from(h))
      ],
      version: json['version'] as String? ?? '1.0',
      author: json['author'] as String? ?? '',
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
    );
  }
}
