import 'package:flutter/material.dart';
import '../widgets/booster_progress_chart_widget.dart';

class BoosterProgressChartScreen extends StatelessWidget {
  static const route = '/booster/progress_chart';
  final List<String> tags;

  const BoosterProgressChartScreen({super.key, required this.tags});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booster Progress')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BoosterProgressChartWidget(tags: tags),
      ),
    );
  }
}
