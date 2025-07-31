import 'package:flutter/material.dart';

import '../services/tag_decay_forecast_service.dart';
import '../widgets/decay_review_timeline_chart.dart';

class MemoryInsightsScreen extends StatefulWidget {
  static const route = '/memory_insights';
  const MemoryInsightsScreen({super.key});

  @override
  State<MemoryInsightsScreen> createState() => _MemoryInsightsScreenState();
}

class _MemoryInsightsScreenState extends State<MemoryInsightsScreen> {
  late Future<Map<String, TagDecayStats>> _future;

  @override
  void initState() {
    super.initState();
    _future = const TagDecayForecastService().summarize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memory Insights')),
      body: FutureBuilder<Map<String, TagDecayStats>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final stats = snapshot.data!;
          if (stats.isEmpty) {
            return const Center(child: Text('No data'));
          }
          final tags = stats.keys.toList()..sort();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DecayReviewTimelineChart(
                stats: stats,
                initialTags: tags.take(3).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
