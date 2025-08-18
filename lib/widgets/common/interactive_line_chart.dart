import 'package:flutter/material.dart';
import 'animated_line_chart.dart';
import 'package:fl_chart/fl_chart.dart';

class InteractiveLineChart extends StatelessWidget {
  final LineChartData data;
  final Duration duration;
  final Curve curve;
  final double minScale;
  final double maxScale;

  const InteractiveLineChart({
    super.key,
    required this.data,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOut,
    this.minScale = 1,
    this.maxScale = 5,
  });

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      panAxis: PanAxis.horizontal,
      minScale: minScale,
      maxScale: maxScale,
      child: AnimatedLineChart(data: data, duration: duration, curve: curve),
    );
  }
}
