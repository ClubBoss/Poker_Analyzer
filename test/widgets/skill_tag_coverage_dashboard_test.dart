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
  final statsWithDates = SkillTagStats(
    tagCounts: {'a': 1, 'b': 1, 'c': 1},
    totalTags: 3,
    unusedTags: const [],
    overloadedTags: const [],
    packsPerTag: const {'a': 1, 'b': 1, 'c': 1},
    tagLastUpdated: {
      'a': DateTime(2023, 5, 1),
      'b': DateTime(2022, 1, 1),
    },
  );

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

  testWidgets('falls back to stats when allTags empty', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SkillTagCoverageDashboard(
        statsStream: Stream.value(stats),
        allTags: {},
        tagCategoryMap: tagCategoryMap,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('c'), findsOneWidget);
  });

  testWidgets('sorts last updated with nulls last', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SkillTagCoverageDashboard(
        statsStream: Stream.value(statsWithDates),
        allTags: const {'a', 'b', 'c'},
        tagCategoryMap: tagCategoryMap,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Last Updated'));
    await tester.pump();

    final bPos = tester.getTopLeft(find.text('b')).dy;
    final aPos = tester.getTopLeft(find.text('a')).dy;
    final cPos = tester.getTopLeft(find.text('c')).dy;

    expect(bPos < aPos, true);
    expect(aPos < cPos, true);
  });

  testWidgets('row colors vary by category', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SkillTagCoverageDashboard(
        statsStream: Stream.value(stats),
        allTags: allTags,
        tagCategoryMap: tagCategoryMap,
      ),
    ));
    await tester.pumpAndSettle();

    final dataTable = tester.widget<DataTable>(find.byType(DataTable));
    final base =
        Theme.of(tester.element(find.byType(DataTable))).colorScheme.surface;
    final rowColorA = dataTable.rows[0].color!.resolve({});
    final rowColorC = dataTable.rows[2].color!.resolve({});
    expect(rowColorA, isNot(equals(base)));
    expect(rowColorA, isNot(equals(rowColorC)));
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

  testWidgets('columns == cells in SkillTagCoverageDashboard', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SkillTagCoverageDashboard(
        statsStream: Stream.value(stats),
        allTags: allTags,
        tagCategoryMap: tagCategoryMap,
      ),
    ));
    await tester.pumpAndSettle();

    final table = tester.widget<DataTable>(find.byType(DataTable));
    expect(table.columns.length, 6);
    expect(table.rows.every((r) => r.cells.length == 6), isTrue);
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
