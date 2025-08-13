import 'package:flutter/material.dart';
import '../services/training_pack_stats_service.dart';
import '../l10n/app_localizations.dart';

class ProgressSummaryCard extends StatefulWidget {
  const ProgressSummaryCard({super.key});

  @override
  State<ProgressSummaryCard> createState() => _ProgressSummaryCardState();
}

class _ProgressSummaryCardState extends State<ProgressSummaryCard>
    with WidgetsBindingObserver {
  GlobalPackStats _stats = const GlobalPackStats();
  GlobalPackStats _old = const GlobalPackStats();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final data = await TrainingPackStatsService.getGlobalStats();
    if (!mounted) return;
    setState(() {
      _old = _stats;
      _stats = data;
    });
  }

  Widget _item(IconData icon, String label, double value,
      {bool percent = false}) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.amberAccent),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 2),
          TweenAnimationBuilder<double>(
            tween: Tween(
                begin: value == _stats.averageAccuracy
                    ? _old.averageAccuracy
                    : _old.averageEV,
                end: value),
            duration: const Duration(milliseconds: 300),
            builder: (context, v, _) => Text(
              percent
                  ? '${(v * 100).toStringAsFixed(1)}%'
                  : v.toStringAsFixed(1),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _item(Icons.percent, l.averageAccuracy, _stats.averageAccuracy,
              percent: true),
          _item(Icons.trending_up, l.averageEv, _stats.averageEV),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.amberAccent),
                const SizedBox(height: 2),
                Text(l.packsCompleted,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 2),
                TweenAnimationBuilder<double>(
                  tween: Tween(
                      begin: _old.packsCompleted.toDouble(),
                      end: _stats.packsCompleted.toDouble()),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, v, _) => Text(
                    v.toStringAsFixed(0),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department,
                    color: Colors.amberAccent),
                const SizedBox(height: 2),
                Text(l.dailyStreak,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 2),
                TweenAnimationBuilder<double>(
                  tween: Tween(
                      begin: _old.dailyStreak.toDouble(),
                      end: _stats.dailyStreak.toDouble()),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, v, _) => Text(
                    v.toStringAsFixed(0),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
