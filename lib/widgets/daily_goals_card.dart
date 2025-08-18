import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/daily_goals_service.dart';
import 'package:poker_analyzer/l10n/app_localizations.dart';

class DailyGoalsCard extends StatelessWidget {
  const DailyGoalsCard({super.key});

  Widget _bar(
    BuildContext context,
    String title,
    double progress,
    double target, {
    int decimals = 0,
  }) {
    final accent = Theme.of(context).colorScheme.secondary;
    final value = target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation(accent),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${progress.toStringAsFixed(decimals)}/${target.toStringAsFixed(decimals)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DailyGoalsService>();
    final l = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.dailyGoals,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _bar(
            context,
            l.sessions,
            service.progressSessions.toDouble(),
            service.targetSessions.toDouble(),
          ),
          _bar(
            context,
            l.accuracyPercent,
            service.progressAccuracy,
            service.targetAccuracy,
          ),
          _bar(
            context,
            l.ev,
            service.progressEv,
            service.targetEv,
            decimals: 1,
          ),
          _bar(
            context,
            l.icm,
            service.progressIcm,
            service.targetIcm,
            decimals: 2,
          ),
        ],
      ),
    );
  }
}
