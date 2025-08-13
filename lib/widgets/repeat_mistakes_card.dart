import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mistake_review_pack_service.dart';
import '../screens/training_pack_review_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RepeatMistakesCard extends StatelessWidget {
  const RepeatMistakesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<MistakeReviewPackService>();
    final pack = service.pack;
    if (pack == null || pack.hands.isEmpty) return const SizedBox.shrink();
    final progress = service.progress;
    final total = pack.hands.length;
    final accent = Theme.of(context).colorScheme.secondary;
    final l = AppLocalizations.of(context)!;
    final value = (progress / total).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.repeat, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.repeatMistakes,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
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
                Text('$progress/$total',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrainingPackReviewScreen(
                    pack: pack,
                    mistakenNames: {for (final h in pack.hands) h.name},
                  ),
                ),
              ).then((_) => service.setProgress(0));
            },
            child: Text(l.startTraining),
          ),
        ],
      ),
    );
  }
}
