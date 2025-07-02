class TrainingPackTemplateModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final int difficulty;
  final Map<String, dynamic> filters;
  final bool isTournament;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime? lastGeneratedAt;

  const TrainingPackTemplateModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.difficulty = 1,
    Map<String, dynamic>? filters,
    this.isTournament = false,
    this.isFavorite = false,
    DateTime? createdAt,
    this.lastGeneratedAt,
  })  : filters = filters ?? const {},
        createdAt = createdAt ?? DateTime.now();

  TrainingPackTemplateModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    int? difficulty,
    Map<String, dynamic>? filters,
    bool? isTournament,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? lastGeneratedAt,
  }) {
    return TrainingPackTemplateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      filters: filters ?? Map<String, dynamic>.from(this.filters),
      isTournament: isTournament ?? this.isTournament,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      lastGeneratedAt: lastGeneratedAt ?? this.lastGeneratedAt,
    );
  }

  factory TrainingPackTemplateModel.fromJson(Map<String, dynamic> json) {
    return TrainingPackTemplateModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
      filters: Map<String, dynamic>.from(json['filters'] as Map? ?? {}),
      isTournament: json['isTournament'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      lastGeneratedAt:
          DateTime.tryParse(json['lastGeneratedAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'difficulty': difficulty,
        'filters': filters,
        'isTournament': isTournament,
        'isFavorite': isFavorite,
        'createdAt': createdAt.toIso8601String(),
        if (lastGeneratedAt != null)
          'lastGeneratedAt': lastGeneratedAt!.toIso8601String(),
      };
}

