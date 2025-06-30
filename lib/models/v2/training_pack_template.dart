import 'training_pack_spot.dart';

class TrainingPackTemplate {
  final String id;
  String name;
  String description;
  String gameType;
  List<TrainingPackSpot> spots;

  TrainingPackTemplate({
    required this.id,
    required this.name,
    this.description = '',
    this.gameType = 'tournament',
    List<TrainingPackSpot>? spots,
  }) : spots = spots ?? [];

  TrainingPackTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? gameType,
    List<TrainingPackSpot>? spots,
  }) {
    return TrainingPackTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      gameType: gameType ?? this.gameType,
      spots: spots ?? List<TrainingPackSpot>.from(this.spots),
    );
  }

  factory TrainingPackTemplate.fromJson(Map<String, dynamic> json) {
    return TrainingPackTemplate(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      gameType: json['gameType'] as String? ?? 'tournament',
      spots: [
        for (final s in (json['spots'] as List? ?? []))
          TrainingPackSpot.fromJson(Map<String, dynamic>.from(s))
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'gameType': gameType,
        if (spots.isNotEmpty) 'spots': [for (final s in spots) s.toJson()],
      };
}
