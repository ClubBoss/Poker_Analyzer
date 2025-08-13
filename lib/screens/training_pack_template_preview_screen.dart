import 'package:flutter/material.dart';

import '../models/v2/training_pack_template.dart';
import '../models/action_entry.dart';
import '../helpers/hand_utils.dart';
import '../services/pack_generator_service.dart';

class TrainingPackTemplatePreviewScreen extends StatelessWidget {
  final TrainingPackTemplate template;
  const TrainingPackTemplatePreviewScreen({super.key, required this.template});

  String _villainRange() {
    final count =
        (PackGeneratorService.handRanking.length * template.bbCallPct / 100)
            .round();
    return PackGeneratorService.handRanking.take(count).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final villain = _villainRange();
    return Scaffold(
      appBar: AppBar(title: Text(template.name)),
      body: ListView.builder(
        itemCount: template.spots.length,
        itemBuilder: (_, i) {
          final s = template.spots[i];
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
