import 'package:flutter/material.dart';
import '../models/v2/training_pack_template.dart';
import '../models/training_pack.dart';
import '../services/booster_stats_tracker_service.dart';
import '../screens/booster_progress_chart_screen.dart';

class BoosterCompletionBanner extends SnackBar {
  BoosterCompletionBanner({
    super.key,
    required BuildContext context,
    required TrainingPackTemplate template,
    required TrainingSessionResult result,
    BoosterStatsTrackerService? service,
  }) : super(
         duration: const Duration(seconds: 5),
         behavior: SnackBarBehavior.floating,
         content: _BoosterCompletionContent(
           template: template,
           result: result,
           service: service ?? BoosterStatsTrackerService(),
           onClose: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
         ),
         action: SnackBarAction(
           label: 'View Progress Chart',
           onPressed: () {
             Navigator.of(context).push(
               MaterialPageRoute(
                 builder: (_) =>
                     BoosterProgressChartScreen(tags: template.tags),
               ),
             );
           },
         ),
       );
}

class _BoosterCompletionContent extends StatefulWidget {
  final TrainingPackTemplate template;
  final TrainingSessionResult result;
  final BoosterStatsTrackerService service;
  final VoidCallback onClose;

  const _BoosterCompletionContent({
    required this.template,
    required this.result,
    required this.service,
    required this.onClose,
  });

  @override
  State<_BoosterCompletionContent> createState() =>
      _BoosterCompletionContentState();
}

class _BoosterCompletionContentState extends State<_BoosterCompletionContent> {
  late Future<Map<String, double>> _deltas;

  @override
  void initState() {
    super.initState();
    _deltas = _load();
  }

  Future<Map<String, double>> _load() async {
    await widget.service.logBoosterResult(widget.template, widget.result);
    final map = <String, double>{};
    for (final tag in widget.template.tags) {
      final history = await widget.service.getProgressForTag(tag);
      if (history.length >= 2) {
        final before = history[history.length - 2].accuracy;
        final after = history.last.accuracy;
        map[tag] = (after - before) * 100;
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: _deltas,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final entries = snapshot.data!.entries.map((e) {
          final delta = e.value;
          final icon = delta >= 0 ? Icons.arrow_upward : Icons.arrow_downward;
          final color = delta >= 0 ? Colors.green : Colors.red;
          final deltaStr =
              '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(0)}%';
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.key),
              const SizedBox(width: 4),
              Icon(icon, size: 16, color: color),
              Text(deltaStr, style: TextStyle(color: color)),
            ],
          );
        }).toList();
        return Row(
          children: [
            Expanded(child: Wrap(spacing: 8, runSpacing: 4, children: entries)),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: widget.onClose,
            ),
          ],
        );
      },
    );
  }
}
