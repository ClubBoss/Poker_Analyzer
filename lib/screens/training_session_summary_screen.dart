import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/combined_progress_bar.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_pack_template.dart';
import '../models/v2/training_session.dart';
import '../services/training_session_service.dart';
import '../widgets/spot_viewer_dialog.dart';
import '../theme/app_colors.dart';
import 'training_session_screen.dart';

class TrainingSessionSummaryScreen extends StatelessWidget {
  final TrainingSession session;
  final TrainingPackTemplate template;
  final double preEvPct;
  final double preIcmPct;
  const TrainingSessionSummaryScreen({
    super.key,
    required this.session,
    required this.template,
    required this.preEvPct,
    required this.preIcmPct,
  });

  @override
  Widget build(BuildContext context) {
    final total = session.results.length;
    final correct = session.results.values.where((e) => e).length;
    final accuracy = total == 0 ? 0.0 : correct * 100 / total;
    final tTotal = template.spots.length;
    final evPct = tTotal == 0 ? 0.0 : template.evCovered * 100 / tTotal;
    final icmPct = tTotal == 0 ? 0.0 : template.icmCovered * 100 / tTotal;
    final mistakes = [
      for (final id in session.results.keys)
        if (session.results[id] == false)
          template.spots.firstWhere(
            (s) => s.id == id,
            orElse: () => TrainingPackSpot(id: ''),
          )
    ].where((s) => s.id.isNotEmpty).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Training Summary')),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                '${accuracy.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            CombinedProgressBar(preEvPct, preIcmPct),
            const SizedBox(height: 4),
            CombinedProgressBar(evPct, icmPct),
            const SizedBox(height: 16),
            if (mistakes.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: mistakes.length,
                  itemBuilder: (context, index) {
                    final s = mistakes[index];
                    return ListTile(
                      title: Text(s.title,
                          style: const TextStyle(color: Colors.white)),
                      trailing: IconButton(
                        icon: const Icon(Icons.replay, color: Colors.orange),
                        onPressed: () => showSpotViewerDialog(context, s),
                      ),
                    );
                  },
                ),
              )
            else
              const Expanded(
                  child: Center(
                      child: Text('No mistakes',
                          style: TextStyle(color: Colors.white70)))),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final service =
                          context.read<TrainingSessionService>();
                      final newSession = await service.startFromMistakes();
                      if (!context.mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TrainingSessionScreen(
                            session: newSession,
                          ),
                        ),
                      );
                    },
                    child: const Text('Repeat Mistakes'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                    child: const Text('Back to Library'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
