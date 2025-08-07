import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_lesson_cluster.dart';
import 'package:poker_analyzer/models/training_pack_model.dart';
import 'package:poker_analyzer/widgets/theory_cluster_pack_heatmap_widget.dart';
import 'package:poker_analyzer/services/theory_lesson_tag_clusterer_service.dart';

class _FakeService implements TheoryLessonTagClustererService {
  final List<TheoryLessonCluster> clusters;
  _FakeService(this.clusters);

  @override
  Future<List<TheoryLessonCluster>> getClusters() async => clusters;

  @override
  void clearCache() {}
}

void main() {
  testWidgets('sorts clusters by coverage', (tester) async {
    final c1 = TheoryLessonCluster(lessons: const [], tags: {'a', 'b'});
    final c2 = TheoryLessonCluster(lessons: const [], tags: {'c'});
    final service = _FakeService([c1, c2]);
    final pack = TrainingPackModel(
      id: '1',
      title: 't',
      spots: const [],
      tags: ['a'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TheoryClusterPackHeatmapWidget(pack: pack, service: service),
      ),
    );
    await tester.pumpAndSettle();

    final indicators = find.byType(LinearProgressIndicator);
    expect(indicators, findsNWidgets(2));

    final first = tester.widget<LinearProgressIndicator>(indicators.at(0));
    final second = tester.widget<LinearProgressIndicator>(indicators.at(1));
    expect(first.value, greaterThan(second.value!));
  });
}
