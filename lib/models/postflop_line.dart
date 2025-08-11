class PostflopLine {
  final String line;
  final int weight;

  const PostflopLine({required this.line, this.weight = 1});

  factory PostflopLine.fromJson(dynamic json) {
    if (json is String) {
      return PostflopLine(line: json);
    }
    if (json is Map) {
      final map = Map<String, dynamic>.from(json);
      final line = map['line']?.toString() ?? '';
      final weight = (map['weight'] as num?)?.toInt() ?? 1;
      return PostflopLine(line: line, weight: weight);
    }
    return const PostflopLine(line: '');
  }

  Map<String, dynamic> toJson() => {
    'line': line,
    if (weight != 1) 'weight': weight,
  };
}
