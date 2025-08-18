import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:poker_analyzer/services/smart_theory_recap_score_weighting.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';

class _FakePathProvider extends PathProviderPlatform {
  final String path;
  _FakePathProvider(this.path);
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

class _FakeLibrary implements MiniLessonLibraryService {
  final List<TheoryMiniLessonNode> lessons;
  _FakeLibrary(this.lessons);

  @override
  List<TheoryMiniLessonNode> get all => lessons;

  @override
  Future<void> loadAll() async {}

  @override
  Future<void> reload() async {}

  @override
  TheoryMiniLessonNode? getById(String id) =>
      lessons.firstWhere((l) => l.id == id, orElse: () => null);

  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) => [];

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('weights recent mistakes higher', () async {
    final dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _FakePathProvider(dir.path);

    final now = DateTime.now();
    final history = [
      {
        'timestamp': now.subtract(const Duration(days: 1)).toIso8601String(),
        'packId': 'p1',
        'spotId': 's1',
        'tags': ['overfoldBtn'],
        'evDiff': -1,
      },
      {
        'timestamp': now.subtract(const Duration(days: 5)).toIso8601String(),
        'packId': 'p2',
        'spotId': 's2',
        'tags': ['looseCallBb'],
        'evDiff': -1,
      },
    ];
    final file = File('${dir.path}/app_data/mistake_tag_history.json');
    await file.create(recursive: true);
    await file.writeAsString(jsonEncode(history), flush: true);

    final lessons = [
      const TheoryMiniLessonNode(
        id: 'l1',
        title: 'Test',
        content: '',
        tags: ['overfoldBtn', 'looseCallBb'],
      ),
    ];
    final service = SmartTheoryRecapScoreWeighting(
      library: _FakeLibrary(lessons),
      cacheDuration: Duration.zero,
    );

    final scores = await service.computeScores([
      'tag:overfoldBtn',
      'tag:looseCallBb',
      'lesson:l1',
    ]);
    expect(scores['tag:overfoldBtn']! > scores['tag:looseCallBb']!, isTrue);
    expect(
      scores['lesson:l1'],
      closeTo((scores['tag:overfoldBtn']! + scores['tag:looseCallBb']!), 0.001),
    );
  });
}
