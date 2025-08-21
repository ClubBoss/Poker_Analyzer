import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/booster_backlink.dart';
import '../models/weak_cluster_info.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/training_pack.dart';
import '../services/training_session_service.dart';
import '../services/booster_recap_hook.dart';
import '../services/booster_mistake_recorder.dart';
import '../theme/app_colors.dart';
import 'training_session_screen.dart';
import '../widgets/theory_progress_recovery_banner.dart';
import '../widgets/booster_recall_banner.dart';
import '../widgets/decay_booster_summary_stats_panel.dart';
import '../models/decay_tag_reinforcement_event.dart';

class BoosterRecapScreen extends StatefulWidget {
  final TrainingSessionResult result;
  final TrainingPackTemplateV2 booster;
  final BoosterBacklink? backlink;
  final WeakClusterInfo? cluster;
  final Map<String, double> tagDeltas;
  final List<DecayTagReinforcementEvent> reinforcements;

  const BoosterRecapScreen({
    super.key,
    required this.result,
    required this.booster,
    this.backlink,
    this.cluster,
    this.tagDeltas = const {},
    this.reinforcements = const [],
  });

  @override
  State<BoosterRecapScreen> createState() => _BoosterRecapScreenState();
}

class _BoosterRecapScreenState extends State<BoosterRecapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BoosterRecapHook.instance.onBoosterResult(
        result: widget.result,
        booster: widget.booster,
        backlink: widget.backlink,
      );
      unawaited(
        BoosterMistakeRecorder.instance.recordSession(
          booster: widget.booster,
          actions: context.read<TrainingSessionService>().actionLog,
          spots: context.read<TrainingSessionService>().spots,
        ),
      );
    });
  }

  List<Widget> _improvementWidgets() {
    final entries = widget.booster.tags
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .map((t) {
      final delta = widget.tagDeltas[t.toLowerCase()] ?? 0.0;
      final sign = delta >= 0 ? '+' : '';
      final pct = (delta * 100).toStringAsFixed(1);
      return '$t: $sign$pct%';
    }).toList();
    if (entries.isEmpty) return [];
    return [
      const Text(
        'Improvement:',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      for (final e in entries)
        Text(e, style: const TextStyle(color: Colors.white70)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    final improvements = _improvementWidgets();
    final clusterTags = widget.backlink?.matchingTags.join(', ');
    return Scaffold(
      appBar: AppBar(title: const Text('Booster Recap')),
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.booster.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.result.correct} / ${widget.result.total}',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              if (improvements.isNotEmpty) ...[
                ...improvements,
                const SizedBox(height: 8),
              ],
              if (clusterTags != null && clusterTags.isNotEmpty) ...[
                Text(
                  'Origin: $clusterTags',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
              ],
              const BoosterRecallBanner(),
              const TheoryProgressRecoveryBanner(),
              DecayBoosterSummaryStatsPanel(events: widget.reinforcements),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.popUntil(context, (r) => r.isFirst),
                      child: const Text('Done'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await context
                            .read<TrainingSessionService>()
                            .startSession(widget.booster);
                        if (!context.mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TrainingSessionScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accent,
                        side: BorderSide(color: accent),
                      ),
                      child: const Text('Train Again'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
