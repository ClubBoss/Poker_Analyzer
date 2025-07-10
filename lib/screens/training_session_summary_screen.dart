import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../widgets/combined_progress_bar.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_pack_template.dart';
import '../models/v2/training_session.dart';
import '../models/v2/hero_position.dart';
import '../services/training_session_service.dart';
import '../services/adaptive_training_service.dart';
import '../services/mistake_review_pack_service.dart';
import '../helpers/mistake_advice.dart';
import '../helpers/poker_street_helper.dart';
import '../widgets/spot_viewer_dialog.dart';
import '../theme/app_colors.dart';
import 'training_session_screen.dart';
import 'v2/training_pack_play_screen.dart';

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
    final l = AppLocalizations.of(context)!;
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
            Builder(
              builder: (context) {
                final adv = <String>{};
                for (final m in mistakes) {
                  for (final t in m.tags) {
                    final a = kMistakeAdvice[t];
                    if (a != null) adv.add(a);
                  }
                  final pos = m.hand.position.label;
                  final pAdv = kMistakeAdvice[pos];
                  if (pAdv != null) adv.add(pAdv);
                  int street = 0;
                  final b = m.hand.board.length;
                  if (b >= 5) street = 3;
                  else if (b == 4) street = 2;
                  else if (b == 3) street = 1;
                  final sAdv = kMistakeAdvice[streetName(street)];
                  if (sAdv != null) adv.add(sAdv);
                }
                final deltaEv = evPct - preEvPct;
                final deltaIcm = icmPct - preIcmPct;
                adv.add('Прогресс EV ${deltaEv >= 0 ? '+' : ''}${deltaEv.toStringAsFixed(1)}%, ICM ${deltaIcm >= 0 ? '+' : ''}${deltaIcm.toStringAsFixed(1)}%');
                final packs = context.watch<AdaptiveTrainingService>().recommended;
                final list = packs.take(3).toList();
                if (adv.isEmpty && list.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final a in adv)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child:
                              Text(a, style: const TextStyle(color: Colors.white)),
                        ),
                      if (list.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('Рекомендуемые паки:',
                            style: TextStyle(color: Colors.white)),
                        const SizedBox(height: 4),
                        for (final p in list)
                          Text(p.name,
                              style:
                                  const TextStyle(color: Colors.white70)),
                      ],
                    ],
                  ),
                );
              },
            ),
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
            if (mistakes.isNotEmpty) ...[
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrainingPackPlayScreen(
                        template: MistakeReviewPackService.cachedTemplate!,
                        original: null,
                      ),
                    ),
                  );
                },
                child: Text(l.reviewMistakes),
              ),
              const SizedBox(height: 8),
            ],
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
