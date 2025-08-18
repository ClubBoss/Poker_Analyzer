import 'lesson_step_filter.dart';

class Quiz {
  final String question;
  final List<String> options;
  final int correctIndex;

  Quiz({
    required this.question,
    required this.options,
    required this.correctIndex,
  }) {
    if (correctIndex < 0 || correctIndex >= options.length) {
      throw ArgumentError('correctIndex out of range');
    }
  }

  factory Quiz.fromYaml(Map yaml) {
    final question = yaml['question']?.toString() ?? '';
    final options = [
      for (final o in (yaml['options'] as List? ?? [])) o.toString(),
    ];
    final index = (yaml['correctIndex'] as num?)?.toInt() ?? 0;
    return Quiz(question: question, options: options, correctIndex: index);
  }

  Map<String, dynamic> toYaml() {
    return {
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
    };
  }
}

class LessonStep {
  final String id;
  final String title;
  final String introText;
  final String summaryText;
  final Quiz? quiz;
  final String? rangeImageUrl;
  final String linkedPackId;
  final LessonStepFilter? filter;
  final Map<String, dynamic> meta;

  LessonStep({
    required this.id,
    required this.title,
    required this.introText,
    this.summaryText = '',
    this.quiz,
    this.rangeImageUrl,
    required this.linkedPackId,
    this.filter,
    Map<String, dynamic>? meta,
  }) : meta = meta ?? const {'schemaVersion': '3.0.0'};

  factory LessonStep.fromYaml(Map yaml) {
    final meta = Map<String, dynamic>.from(yaml['meta'] as Map? ?? {});
    meta['schemaVersion'] = meta['schemaVersion']?.toString() ?? '3.0.0';
    final quizYaml = yaml['quiz'] as Map?;
    final quiz = quizYaml != null ? Quiz.fromYaml(Map.from(quizYaml)) : null;
    final filterYaml = yaml['filter'];
    LessonStepFilter? filter;
    if (filterYaml is Map) {
      filter = LessonStepFilter.fromYaml(Map<String, dynamic>.from(filterYaml));
    }
    return LessonStep(
      id: yaml['id']?.toString() ?? '',
      title: yaml['title']?.toString() ?? '',
      introText: yaml['introText']?.toString() ?? '',
      summaryText: yaml['summaryText']?.toString() ?? '',
      quiz: quiz,
      rangeImageUrl: yaml['rangeImageUrl']?.toString(),
      linkedPackId: yaml['linkedPackId']?.toString() ?? '',
      filter: filter,
      meta: meta,
    );
  }

  Map<String, dynamic> toYaml() {
    return {
      'meta': meta,
      'id': id,
      'title': title,
      'introText': introText,
      'summaryText': summaryText,
      if (quiz != null) 'quiz': quiz!.toYaml(),
      if (rangeImageUrl != null) 'rangeImageUrl': rangeImageUrl,
      'linkedPackId': linkedPackId,
      if (filter != null) 'filter': filter!.toYaml(),
    };
  }
}
