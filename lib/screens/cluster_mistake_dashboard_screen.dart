import 'dart:math';
import 'package:flutter/material.dart';

import '../services/mistake_tag_insights_service.dart';
import '../services/mistake_cluster_analytics_service.dart';
import '../screens/mistake_review_screen.dart';
import '../theme/app_colors.dart';

class ClusterMistakeDashboardScreen extends StatefulWidget {
  static const route = '/mistake_clusters';
  const ClusterMistakeDashboardScreen({super.key});

  @override
  State<ClusterMistakeDashboardScreen> createState() =>
      _ClusterMistakeDashboardScreenState();
}

enum _SortMode { mistakes, evLoss }

class _ClusterMistakeDashboardScreenState
    extends State<ClusterMistakeDashboardScreen> {
  bool _loading = true;
  List<ClusterAnalytics> _clusters = [];
  _SortMode _sort = _SortMode.mistakes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final insights = await const MistakeTagInsightsService().buildInsights();
    final clusters = const MistakeClusterAnalyticsService().compute(insights);
    setState(() {
      _clusters = clusters;
      _loading = false;
    });
  }

  void _toggleSort() {
    setState(() {
      if (_sort == _SortMode.mistakes) {
        _clusters = const MistakeClusterAnalyticsService().sortByEvLoss(
          _clusters,
        );
        _sort = _SortMode.evLoss;
      } else {
        _clusters = const MistakeClusterAnalyticsService().sortByMistakes(
          _clusters,
        );
        _sort = _SortMode.mistakes;
      }
    });
  }

  void _startReview() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MistakeReviewScreen()),
    );
  }

  Widget _clusterCard(ClusterAnalytics c, double maxLoss) {
    final ratio = maxLoss > 0 ? c.totalEvLoss / maxLoss : 0.0;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c.cluster.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ошибок: ${c.totalMistakes} · EV потеря: ${c.totalEvLoss.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.redAccent,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _startReview,
                child: const Text('Review mistakes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxLoss = _clusters.isEmpty
        ? 0.0
        : _clusters.map((e) => e.totalEvLoss).reduce(max);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mistake Clusters'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _toggleSort,
            tooltip: _sort == _SortMode.mistakes
                ? 'Sort by EV loss'
                : 'Sort by count',
            icon: Icon(
              _sort == _SortMode.mistakes
                  ? Icons.trending_down
                  : Icons.format_list_numbered,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _clusters.isEmpty
          ? const Center(
              child: Text(
                'Нет данных',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView(
              children: [for (final c in _clusters) _clusterCard(c, maxLoss)],
            ),
    );
  }
}
