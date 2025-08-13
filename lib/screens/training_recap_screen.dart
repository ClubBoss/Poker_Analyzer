import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../services/training_session_service.dart';
import '../services/training_pack_template_service.dart';
import '../widgets/skill_mastery_chart_widget.dart';
import '../widgets/next_pack_recommendation_banner.dart';
import '../widgets/theory_progress_recovery_banner.dart';
import '../services/user_action_logger.dart';
import 'training_session_screen.dart';
import '../utils/context_extensions.dart';

class TrainingRecapScreen extends StatefulWidget {
  final String templateId;
  final int correct;
  final int total;
  final Duration elapsed;
  const TrainingRecapScreen({
    super.key,
    required this.templateId,
    required this.correct,
    required this.total,
    required this.elapsed,
  });

  @override
  State<TrainingRecapScreen> createState() => _TrainingRecapScreenState();
}

class _TrainingRecapScreenState extends State<TrainingRecapScreen> {
  @override
  void initState() {
    super.initState();
    UserActionLogger.instance.log('recap_viewed');
  }

  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Future<void> _repeat() async {
    final tpl = TrainingPackTemplateService.getById(widget.templateId, context);
    if (tpl == null) return;
    await context.read<TrainingSessionService>().startSession(tpl);
    await context.ifMounted(() async {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
      );
    });
  }

  Future<void> _reviewMistakes() async {
    final service = context.read<TrainingSessionService>();
    final session = await service.startFromMistakes();
    await context.ifMounted(() async {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TrainingSessionScreen(session: session),
        ),
      );
    });
  }

  void _back() {
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final acc = widget.total == 0 ? 0.0 : widget.correct * 100 / widget.total;
    return Scaffold(
      appBar: AppBar(title: const Text('Session Recap')),
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
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
                      '${widget.correct} / ${widget.total}',
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
                    Text(
                      'Time: ${_format(widget.elapsed)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SkillMasteryChartWidget(),
              NextPackRecommendationBanner(currentPackId: widget.templateId),
              const TheoryProgressRecoveryBanner(),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: _repeat,
                  child: const Text('Repeat Pack'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: _reviewMistakes,
                  child: const Text('Review Mistakes'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 200,
                child: OutlinedButton(
                  onPressed: _back,
                  child: const Text('Back to Library'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
