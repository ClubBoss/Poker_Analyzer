import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/leak_insight.dart';
import '../services/session_log_service.dart';
import '../services/pack_library_loader_service.dart';
import '../services/training_session_launcher.dart';
import '../services/weakness_insight_service.dart';

/// Banner showing the top leak detected from recent sessions.
class LeakInsightBanner extends StatefulWidget {
  const LeakInsightBanner({super.key});

  @override
  State<LeakInsightBanner> createState() => _LeakInsightBannerState();
}

class _LeakInsightBannerState extends State<LeakInsightBanner> {
  late Future<LeakInsight?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<LeakInsight?> _load() async {
    final logs = context.read<SessionLogService>().logs;
    await PackLibraryLoaderService.instance.loadLibrary();
    final packs = PackLibraryLoaderService.instance.library;
    final insights = const WeaknessInsightService().analyze(
      logs: logs,
      packs: packs,
    );
    if (insights.isEmpty) return null;
    final top = insights.first;
    if (top.leakScore < 0.25) return null;
    return top;
  }

  Future<void> _train(LeakInsight leak) async {
    final pack = await PackLibraryLoaderService.instance
        .loadLibrary()
        .then((_) => PackLibraryLoaderService.instance.library)
        .then((list) => list.firstWhere((p) => p.id == leak.suggestedPackId,
            orElse: () => null));
    await const TrainingSessionLauncher().launch(pack);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return FutureBuilder<LeakInsight?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final leak = snapshot.data;
        if (leak == null) return const SizedBox.shrink();
        final label = '${leak.tag} • ${leak.position} • ${leak.stack}bb';
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.insights, color: accent),
                  const SizedBox(width: 8),
                  const Text(
                    'Weakest Spot',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    final l = leak;
                    _train(l);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: accent),
                  child: const Text('Train this spot'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
