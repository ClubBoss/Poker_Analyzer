import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poker_analyzer/services/booster_stats_tracker_service.dart';
import 'package:poker_analyzer/widgets/booster_progress_chart_widget.dart';

class _FakeService extends BoosterStatsTrackerService {
  _FakeService(this.data);
  final Map<String, List<BoosterTagProgress>> data;

  @override
  Future<List<BoosterTagProgress>> getProgressForTag(String tag) async {
    return data[tag] ?? [];
  }
}

void main() {
  testWidgets('shows legend for each tag', (tester) async {
    final service = _FakeService({
      'btn': [
        BoosterTagProgress(date: DateTime(2024, 1, 1), accuracy: 0.5),
        BoosterTagProgress(date: DateTime(2024, 1, 2), accuracy: 0.6),
      ],
      'bbVsBtn': [
        BoosterTagProgress(date: DateTime(2024, 1, 1), accuracy: 0.4),
        BoosterTagProgress(date: DateTime(2024, 1, 3), accuracy: 0.7),
      ],
    });

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 200,
          child: BoosterProgressChartWidget(
            tags: const ['btn', 'bbVsBtn'],
            service: service,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('btn'), findsOneWidget);
    expect(find.text('bbVsBtn'), findsOneWidget);
  });
}

