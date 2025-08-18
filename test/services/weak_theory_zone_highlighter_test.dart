import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/player_profile.dart';
import 'package:poker_analyzer/models/theory_cluster_summary.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/weak_theory_zone_highlighter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final lessons = <String, TheoryMiniLessonNode>{
    'l1': const TheoryMiniLessonNode(
      id: 'l1',
      title: 'L1',
      content: '',
      tags: ['a', 'b'],
    ),
    'l2': const TheoryMiniLessonNode(
      id: 'l2',
      title: 'L2',
      content: '',
      tags: ['a'],
    ),
    'l3': const TheoryMiniLessonNode(
      id: 'l3',
      title: 'L3',
      content: '',
      tags: ['b'],
    ),
    'l4': const TheoryMiniLessonNode(
      id: 'l4',
      title: 'L4',
      content: '',
      tags: ['c'],
    ),
  };

  test('detectWeakTags ranks by accuracy and coverage', () {
    final profile = PlayerProfile(
      completedLessonIds: {'l1', 'l3'},
      tagAccuracy: {'a': 0.6, 'b': 0.8, 'c': 1.0},
    );
    const service = WeakTheoryZoneHighlighter();

    final result = service.detectWeakTags(profile: profile, lessons: lessons);

    expect(result.first.tag, 'c');
    expect(result[1].tag, 'a');
    expect(result.last.tag, 'b');
  });

  test('detectWeakClusters uses tag scores and coverage', () {
    final profile = PlayerProfile(
      completedLessonIds: {'l1', 'l3'},
      tagAccuracy: {'a': 0.6, 'b': 0.8, 'c': 1.0},
    );
    final clusters = [
      const TheoryClusterSummary(
        size: 2,
        entryPointIds: ['l1'],
        sharedTags: {'a'},
      ),
      const TheoryClusterSummary(
        size: 2,
        entryPointIds: ['l3'],
        sharedTags: {'b'},
      ),
    ];

    const service = WeakTheoryZoneHighlighter();
    final result = service.detectWeakClusters(
      profile: profile,
      clusters: clusters,
      lessons: lessons,
    );

    expect(result.first.cluster.sharedTags, {'a'});
    expect(result.last.cluster.sharedTags, {'b'});
  });
}
