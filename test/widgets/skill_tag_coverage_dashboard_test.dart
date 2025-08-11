import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/skill_tag_stats.dart';
import 'package:poker_analyzer/utils/skill_tag_coverage_utils.dart';
import 'package:poker_analyzer/widgets/skill_tag_coverage_dashboard.dart';

void main() {
  final stats = SkillTagStats(
    tagCounts: {'a': 5, 'b': 1, 'c': 0},
    totalTags: 6,
    unusedTags: const [],
    overloadedTags: const [],
    packsPerTag: const {'a': 3, 'b': 1, 'c': 0},
    tagLastUpdated: const {},
  );
  final allTags = {'a', 'b', 'c'};
  final tagCategoryMap = {'a': 'cat1', 'b': 'cat1', 'c': 'cat2'};

  testWidgets('sorts by spots covered', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SkillTagCoverageDashboard(
        statsStream: Stream.value(stats),
        allTags: allTags,
        tagCategoryMap: tagCategoryMap,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Spots Covered'));
    await tester.pump();

    final cPos = tester.getTopLeft(find.text('c')).dy;
    final bPos = tester.getTopLeft(find.text('b')).dy;
    final aPos = tester.getTopLeft(find.text('a')).dy;

    expect(cPos < bPos, true);
    expect(bPos < aPos, true);
  });

  testWidgets('filters uncovered tags', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SkillTagCoverageDashboard(
        statsStream: Stream.value(stats),
        allTags: allTags,
        tagCategoryMap: tagCategoryMap,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(find.text('c'), findsOneWidget);
    expect(find.text('a'), findsNothing);
  });

  test('computeCategorySummary aggregates', () {
    final summary = computeCategorySummary(stats, allTags, tagCategoryMap);
    final cat1 = summary['cat1']!;
    final cat2 = summary['cat2']!;

    expect(cat1.total, 2);
    expect(cat1.covered, 2);
    expect(cat1.uncovered, 0);
    expect(cat1.avg, 100);

    expect(cat2.total, 1);
    expect(cat2.covered, 0);
    expect(cat2.uncovered, 1);
    expect(cat2.avg, 0);
  });
}

