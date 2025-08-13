import 'package:flutter/material.dart';

import '../models/decay_retention_summary.dart';
import '../models/daily_review_plan.dart';
import '../services/decay_retention_summary_service.dart';
import '../services/decay_smart_scheduler_service.dart';
import '../services/daily_review_booster_launcher.dart';

class DecayDashboardScreen extends StatefulWidget {
  static const route = '/decay_dashboard';
  const DecayDashboardScreen({super.key});

  @override
  State<DecayDashboardScreen> createState() => _DecayDashboardScreenState();
}

class _DecayDashboardScreenState extends State<DecayDashboardScreen> {
  bool _loading = true;
  DecayRetentionSummary? _summary;
  DailyReviewPlan? _plan;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final summary = await DecayRetentionSummaryService().getSummary();
    final plan = await DecaySmartSchedulerService().generateTodayPlan();
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _plan = plan;
      _loading = false;
    });
  }

  Future<void> _startReview() async {
    await const DailyReviewBoosterLauncher().launch(context);
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
          Text('Всего тегов: ${s.totalTags}',
              style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 4),
          Text('Средний decay: ${(s.averageDecay * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text('Забытых тегов: ${s.decayedTags}',
              style: const TextStyle(color: Colors.white70)),
          if (s.topForgotten.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Топ забытых: ${s.topForgotten.join(', ')}',
                style: const TextStyle(color: Colors.white70)),
          ],
        ],
      ),
    );
  }

  Widget _planSection() {
    final plan = _plan;
    if (plan == null || plan.tags.isEmpty) return const SizedBox.shrink();
    final tags = plan.tags.join(', ');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('План на сегодня',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(tags, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memory Health')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _summarySection(),
                const SizedBox(height: 16),
                _planSection(),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _startReview,
                  child: const Text('Начать повторение'),
                ),
              ],
            ),
    );
  }
}
