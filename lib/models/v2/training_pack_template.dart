class TrainingPackTemplate {
  final String id;
  String name;
  String description;

  TrainingPackTemplate({required this.id, required this.name, this.description = ''});

  TrainingPackTemplate copyWith({String? id, String? name, String? description}) {
    return TrainingPackTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }

  factory TrainingPackTemplate.fromJson(Map<String, dynamic> json) {
    return TrainingPackTemplate(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
      };
}
