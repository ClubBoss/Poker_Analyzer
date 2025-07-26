class TheoryPackModel {
  final String id;
  final String title;
  final List<TheorySectionModel> sections;

  TheoryPackModel({
    required this.id,
    required this.title,
    required this.sections,
  });
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
}
