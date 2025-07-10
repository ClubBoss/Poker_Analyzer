import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnimatedBarChart extends StatelessWidget {
  final BarChartData data;
  final Duration duration;
  final Curve curve;

  const AnimatedBarChart({
    super.key,
    required this.data,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOut,
  });

  @override
  Widget build(BuildContext context) {
    return BarChart(
      data,
      swapAnimationDuration: duration,
      swapAnimationCurve: curve,
    );
  }
}
