import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/date_utils.dart';
import '../services/training_pack_template_service.dart';
import '../services/training_session_service.dart';
import '../models/v2/training_pack_template.dart';
import 'training_session_screen.dart';
import 'pack_history_screen.dart';
import '../widgets/next_pack_recommendation_banner.dart';
import '../widgets/skill_mastery_chart_widget.dart';
import '../widgets/theory_progress_recovery_banner.dart';

class PackStatsScreen extends StatelessWidget {
  final String templateId;
  final int correct;
  final int total;
  final DateTime completedAt;
  final Map<String, int>? categoryCounts;
  const PackStatsScreen({
    super.key,
    required this.templateId,
    required this.correct,
    required this.total,
    required this.completedAt,
    this.categoryCounts,
  });

  TrainingPackTemplate? _template(BuildContext context) {
    for (final t in TrainingPackTemplateService.getAllTemplates(context)) {
      if (t.id == templateId) return t;
    }
    return null;
  }

  Future<void> _repeat(BuildContext context) async {
    final tpl = _template(context);
    if (tpl == null) return;
    await context.read<TrainingSessionService>().startSession(tpl);
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
      );
    }
  }

  void _openHistory(BuildContext context) {
    final tpl = _template(context);
    if (tpl == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PackHistoryScreen(templateId: tpl.id, title: tpl.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final acc = total == 0 ? 0.0 : correct * 100 / total;
    final date = formatDateTime(completedAt);
    return Scaffold(
      appBar: AppBar(title: const Text('Pack Stats')),
      backgroundColor: const Color(0xFF1B1C1E),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3B3E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$correct / $total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Accuracy ${acc.toStringAsFixed(1)}%',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(date, style: const TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
              if (categoryCounts != null && categoryCounts!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final e in categoryCounts!.entries)
                      Text(
                        '${e.key} - ${e.value}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () => _repeat(context),
                  child: const Text('Repeat Pack'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () => _openHistory(context),
                  child: const Text('History'),
                ),
              ),
              const SkillMasteryChartWidget(),
              NextPackRecommendationBanner(currentPackId: templateId),
              const TheoryProgressRecoveryBanner(),
            ],
          ),
        ),
      ),
    );
  }
}
