class TrainingPackTemplate {
  final String id;
  String name;
  TrainingPackTemplate({required this.id, required this.name});
  TrainingPackTemplate copyWith({String? id, String? name}) {
    return TrainingPackTemplate(id: id ?? this.id, name: name ?? this.name);
  }
  factory TrainingPackTemplate.fromJson(Map<String, dynamic> json) {
    return TrainingPackTemplate(id: json['id'] as String? ?? '', name: json['name'] as String? ?? '');
  }
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
