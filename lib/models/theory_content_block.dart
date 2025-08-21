class TheoryContentBlock {
  final String id;
  final String title;
  final String content;

  const TheoryContentBlock({
    required this.id,
    required this.title,
    required this.content,
  });

  factory TheoryContentBlock.fromYaml(Map yaml) {
    return TheoryContentBlock(
      id: yaml['id']?.toString() ?? '',
      title: yaml['title']?.toString() ?? '',
      content: yaml['content']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
  };
}
