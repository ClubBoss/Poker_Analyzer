import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnimatedLineChart extends StatelessWidget {
  final LineChartData data;
  final Duration duration;
  final Curve curve;

  const AnimatedLineChart({
    super.key,
    required this.data,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOut,
  });

  @override
  Widget build(BuildContext context) {
    return LineChart(
      data,
      swapAnimationDuration: duration,
      swapAnimationCurve: curve,
    );
  }
}
