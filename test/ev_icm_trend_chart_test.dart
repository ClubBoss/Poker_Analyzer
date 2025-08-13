import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/widgets/common/ev_icm_trend_chart.dart';
import 'package:poker_analyzer/services/progress_forecast_service.dart';
import 'package:poker_analyzer/widgets/common/animated_line_chart.dart';

void main() {
  testWidgets('renders correct spots and axis', (tester) async {
    final data = [
      ProgressEntry(
          date: DateTime(2023, 1, 1),
          accuracy: 0,
          ev: -1,
          icm: -0.5,
          position: ''),
      ProgressEntry(
          date: DateTime(2023, 1, 2),
          accuracy: 0,
          ev: 0.5,
          icm: 0.8,
          position: ''),
      ProgressEntry(
          date: DateTime(2023, 1, 3),
          accuracy: 0,
          ev: 2,
          icm: 1.5,
          position: ''),
    ];
    await tester.pumpWidget(MaterialApp(home: EvIcmTrendChart(data: data)));
    final chart =
        tester.widget<AnimatedLineChart>(find.byType(AnimatedLineChart));
    final bars = chart.data.lineBarsData;
    expect(bars[0].spots.length, data.length);
    expect(bars[1].spots.length, data.length);
    expect(chart.data.minY, -1);
    expect(chart.data.maxY, 2);
  });
}
