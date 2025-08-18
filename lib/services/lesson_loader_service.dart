import 'package:flutter/services.dart' show rootBundle;

import '../core/training/generation/yaml_reader.dart';
import '../models/v3/lesson_step.dart';

class LessonLoaderService {
  LessonLoaderService._();
  static final instance = LessonLoaderService._();

  List<LessonStep>? _cache;

  Future<List<LessonStep>> loadAllLessons() async {
    final cached = _cache;
    if (cached != null) return cached;
    const files = ['assets/lessons/test_lesson.yaml'];
    final steps = <LessonStep>[];
    for (final path in files) {
      try {
        final raw = await rootBundle.loadString(path);
        final map = const YamlReader().read(raw);
        final meta = map['meta'] as Map?;
        final schema = meta?['schemaVersion']?.toString();
        if (schema != '3.0.0') continue;
        steps.add(LessonStep.fromYaml(Map<String, dynamic>.from(map)));
      } catch (_) {}
    }
    steps.sort((a, b) => a.id.compareTo(b.id));
    _cache = steps;
    return steps;
  }
}
