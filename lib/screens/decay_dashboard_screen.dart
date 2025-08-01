import 'dart:async';

import 'package:flutter/material.dart';

import '../models/decay_forecast_alert.dart';
import '../models/tag_decay_summary.dart';
import '../services/decay_forecast_alert_service.dart';
import '../services/decay_heatmap_model_generator.dart';
import '../services/decay_tag_retention_tracker_service.dart';
import '../services/inbox_booster_delivery_controller.dart';
import '../services/inbox_booster_tuner_service.dart';
import '../services/recall_success_logger_service.dart';
import '../services/recall_tag_decay_summary_service.dart';
import '../widgets/decay_heatmap_ui_surface.dart';

class DecayDashboardScreen extends StatefulWidget {
  static const route = '/decay_dashboard';
  const DecayDashboardScreen({super.key});

  @override
  State<DecayDashboardScreen> createState() => _DecayDashboardScreenState();
}

class _DecayDashboardScreenState extends State<DecayDashboardScreen> {
  bool _loading = true;
  TagDecaySummary? _summary;
  List<DecayHeatmapEntry> _heatmap = [];
  List<DecayForecastAlert> _alerts = [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final summaryService = RecallTagDecaySummaryService();
    final recallSummary = await summaryService.getSummary();

    final logger = RecallSuccessLoggerService.instance;
    final tuner = InboxBoosterTunerService.instance;
    final retention = const DecayTagRetentionTrackerService();

    final successes = await logger.getSuccesses();
    final fromLogs = successes
        .map((e) => e.tag.trim().toLowerCase())
        .where((t) => t.isNotEmpty);
    final boostScores = await tuner.computeTagBoostScores();
    final fromBoost = boostScores.keys
        .map((e) => e.trim().toLowerCase())
        .where((t) => t.isNotEmpty);
    final tags = {...fromLogs, ...fromBoost};

    final scores = <String, double>{};
    for (final tag in tags) {
      scores[tag] = await retention.getDecayScore(tag);
    }

    final generator = DecayHeatmapModelGenerator();
    final heatmap = generator.generate(scores);

    final alerts = await const DecayForecastAlertService()
        .getUpcomingCriticalTags(tags.toList());

    if (!mounted) return;
    setState(() {
      _summary = recallSummary;
      _heatmap = heatmap;
      _alerts = alerts;
      _loading = false;
    });
  }

  Future<void> _reviewNow() async {
    await InboxBoosterDeliveryController().maybeTriggerBoosterInbox();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review triggered')),
    );
  }

  Widget _summarySection() {
    final s = _summary;
    if (s == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Avg Decay: ${s.avgDecay.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 4),
          Text('Critical: ${s.countCritical} · Warning: ${s.countWarning}',
              style: const TextStyle(color: Colors.white70)),
          if (s.mostDecayedTags.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Most at risk: ${s.mostDecayedTags.join(', ')}',
                style: const TextStyle(color: Colors.white70)),
          ],
        ],
      ),
    );
  }

  Widget _alertsSection() {
    if (_alerts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Risk',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        for (final a in _alerts)
          Text(
            '${a.tag} → ${a.projectedDecay.toStringAsFixed(0)} in ${a.daysToCritical}d',
            style: const TextStyle(color: Colors.white70),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memory Health')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _heatmap.isEmpty && _alerts.isEmpty
              ? const Center(
                  child:
                      Text('No tags', style: TextStyle(color: Colors.white70)),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _summarySection(),
                    const SizedBox(height: 16),
                    if (_heatmap.isNotEmpty)
                      DecayHeatmapUISurface(data: _heatmap),
                    const SizedBox(height: 16),
                    _alertsSection(),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _reviewNow,
                      child: const Text('Review Now'),
                    ),
                  ],
                ),
    );
  }
}
