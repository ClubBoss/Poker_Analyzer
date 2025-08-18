import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:poker_analyzer/services/theory_booster_candidate_picker.dart';
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
  List<TheoryMiniLessonNode> findByTags(List<String> tags) {
    final lc = tags.map((e) => e.toLowerCase()).toSet();
    final result = <TheoryMiniLessonNode>[];
    for (final l in lessons) {
      final tagsLc = l.tags.map((e) => e.toLowerCase());
      if (tagsLc.any(lc.contains)) result.add(l);
    }
    return result;
  }

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) =>
      findByTags(tags.toList());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('picks lessons for repeated mistake tags', () async {
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
        'timestamp': now.subtract(const Duration(days: 2)).toIso8601String(),
        'packId': 'p2',
        'spotId': 's2',
        'tags': ['overfoldBtn'],
        'evDiff': -2,
      },
      {
        'timestamp': now.subtract(const Duration(days: 3)).toIso8601String(),
        'packId': 'p1',
        'spotId': 's3',
        'tags': ['overfoldBtn'],
        'evDiff': -0.5,
      },
      {
        'timestamp': now.subtract(const Duration(days: 1)).toIso8601String(),
        'packId': 'p1',
        'spotId': 's4',
        'tags': ['looseCallBb'],
        'evDiff': -0.8,
      },
    ];
    final file = File('${dir.path}/app_data/mistake_tag_history.json');
    await file.create(recursive: true);
    await file.writeAsString(jsonEncode(history), flush: true);

    final lessons = [
      const TheoryMiniLessonNode(
        id: 'l1',
        title: 'BTN Overfold',
        content: '',
        tags: ['btn overfold'],
      ),
      const TheoryMiniLessonNode(
        id: 'l2',
        title: 'Loose Calls',
        content: '',
        tags: ['loose call bb'],
      ),
    ];
    final picker = TheoryBoosterCandidatePicker(library: _FakeLibrary(lessons));

    final result = await picker.getTopBoosterCandidates();
    expect(result.map((e) => e.id).toList(), ['l1']);
  });
}
