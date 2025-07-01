import 'training_pack_spot.dart';
import '../game_type.dart';
import '../training_pack.dart' show parseGameType;

class TrainingPackTemplate {
  final String id;
  String name;
  String description;
  GameType gameType;
  List<TrainingPackSpot> spots;
  List<String> tags;

  TrainingPackTemplate({
    required this.id,
    required this.name,
    this.description = '',
    this.gameType = GameType.tournament,
    List<TrainingPackSpot>? spots,
    List<String>? tags,
  })  : spots = spots ?? [],
        tags = tags ?? [];

  TrainingPackTemplate copyWith({
    String? id,
    String? name,
    String? description,
    GameType? gameType,
    List<TrainingPackSpot>? spots,
    List<String>? tags,
  }) {
    return TrainingPackTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      gameType: gameType ?? this.gameType,
      spots: spots ?? List<TrainingPackSpot>.from(this.spots),
      tags: tags ?? List<String>.from(this.tags),
    );
  }

  factory TrainingPackTemplate.fromJson(Map<String, dynamic> json) {
    return TrainingPackTemplate(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      gameType: parseGameType(json['gameType']),
      spots: [
        for (final s in (json['spots'] as List? ?? []))
          TrainingPackSpot.fromJson(Map<String, dynamic>.from(s))
      ],
      tags: [for (final t in (json['tags'] as List? ?? [])) t as String],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'gameType': gameType.name,
        if (spots.isNotEmpty) 'spots': [for (final s in spots) s.toJson()],
        if (tags.isNotEmpty) 'tags': tags,
      };
}
