import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/v2/training_pack_template.dart';
import '../models/action_entry.dart';
import '../helpers/hand_utils.dart';
import '../services/pack_generator_service.dart';
import '../services/training_session_service.dart';
import 'training_session_screen.dart';

class PackPreviewScreen extends StatelessWidget {
  final TrainingPackTemplate pack;
  const PackPreviewScreen({super.key, required this.pack});

  String _villainRange() {
    final count =
        (PackGeneratorService.handRanking.length * pack.bbCallPct / 100).round();
    return PackGeneratorService.handRanking.take(count).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final villain = _villainRange();
    return Scaffold(
      appBar: AppBar(
        title: Text(pack.name),
        actions: [
          TextButton(
            onPressed: () async {
              final session =
                  await context.read<TrainingSessionService>().startFromTemplate(pack);
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => TrainingSessionScreen(session: session),
                ),
              );
            },
            child: const Text('Start', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: pack.spots.length,
        itemBuilder: (_, i) {
          final s = pack.spots[i];
          final hero = handCode(s.hand.heroCards) ?? s.hand.heroCards;
          final actions = s.hand.actions[0] ?? [];
          ActionEntry? heroAct;
          for (final a in actions) {
            if (a.playerIndex == s.hand.heroIndex) {
              heroAct = a;
              break;
            }
          }
          final act = heroAct?.customLabel ?? heroAct?.action;
          return ListTile(
            leading: Text('${i + 1}'),
            title: Text(s.title.isEmpty ? 'Spot ${i + 1}' : s.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hero: $hero'),
                Text('Villain: $villain'),
                if (act != null) Text('Action: $act'),
              ],
            ),
          );
        },
      ),
    );
  }
}
