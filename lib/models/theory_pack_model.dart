class TheoryPackModel {
  final String id;
  final String title;
  final List<TheorySectionModel> sections;

  TheoryPackModel({
    required this.id,
    required this.title,
    required this.sections,
  });

  factory TheoryPackModel.fromYaml(Map yaml) {
    final id = yaml['id']?.toString() ?? '';
    final title = yaml['title']?.toString() ?? '';
    final secYaml = yaml['sections'];
    final sections = <TheorySectionModel>[];
    if (secYaml is List) {
      for (final s in secYaml) {
        if (s is Map) {
          sections.add(
            TheorySectionModel.fromYaml(Map<String, dynamic>.from(s)),
          );
        }
      }
    }
    return TheoryPackModel(id: id, title: title, sections: sections);
  }
}

class TheorySectionModel {
  final String title;
  final String text;
  final String type;

  TheorySectionModel({
    required this.title,
    required this.text,
    required this.type,
  });

  factory TheorySectionModel.fromYaml(Map yaml) {
    return TheorySectionModel(
      title: yaml['title']?.toString() ?? '',
      text: yaml['text']?.toString() ?? '',
      type: yaml['type']?.toString() ?? '',
    );
  }
}
