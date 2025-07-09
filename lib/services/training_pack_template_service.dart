import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/v2/training_pack_preset.dart';
import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/hero_position.dart';
import '../models/game_type.dart';
import '../models/action_entry.dart';
import 'pack_generator_service.dart';

class TrainingPackTemplateService {
  static final TrainingPackTemplate _starterPushfold10bb = TrainingPackTemplate(
    id: 'starter_pushfold_10bb',
    name: 'Push/Fold 10BB (No Ante)',
    difficulty: '1',
    createdAt: DateTime(2024, 7, 9),
    gameType: GameType.tournament,
    heroBbStack: 10,
    playerStacksBb: const [10, 10],
    heroPos: HeroPosition.sb,
    anteBb: 0,
    tags: const ['starter', 'push', '10bb', 'no_ante'],
    isBuiltIn: true,
    spots: [
      TrainingPackSpot(
        id: 'pf10_1',
        title: 'A9o push',
        hand: HandData(
          heroCards: 'As 9d',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 10, '1': 10},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 10, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf10_2',
        title: 'Q6s fold',
        hand: HandData(
          heroCards: 'Qs 6s',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 10, '1': 10},
          actions: {
            0: [ActionEntry(0, 0, 'fold', ev: 0.0)]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf10_3',
        title: '22 push call',
        hand: HandData(
          heroCards: '2c 2d',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 10, '1': 10},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 10, ev: 0.5),
              ActionEntry(0, 1, 'call', amount: 10, ev: 0.5),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf10_4',
        title: 'J9s push',
        hand: HandData(
          heroCards: 'Jh 9h',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 10, '1': 10},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 10, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf10_5',
        title: 'KTo push',
        hand: HandData(
          heroCards: 'Kh Td',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 10, '1': 10},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 10, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf10_6',
        title: 'Q9s push',
        hand: HandData(
          heroCards: 'Qd 9d',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 10, '1': 10},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 10, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf10_7',
        title: 'A5s push',
        hand: HandData(
          heroCards: 'Ah 5h',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 10, '1': 10},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 10, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf10_8',
        title: '77 push',
        hand: HandData(
          heroCards: '7h 7c',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 10, '1': 10},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 10, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf10_9',
        title: 'T8o fold',
        hand: HandData(
          heroCards: 'Td 8c',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 10, '1': 10},
          actions: {
            0: [ActionEntry(0, 0, 'fold', ev: 0.0)]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf10_10',
        title: '99 push call',
        hand: HandData(
          heroCards: '9s 9d',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 10, '1': 10},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 10, ev: 0.5),
              ActionEntry(0, 1, 'call', amount: 10, ev: 0.5),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf10_11',
        title: 'BTN A8s push',
        hand: HandData(
          heroCards: 'Ah 8h',
          position: HeroPosition.btn,
          heroIndex: 0,
          playerCount: 3,
          stacks: {'0': 10, '1': 10, '2': 10},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 10, ev: 0.5),
              ActionEntry(0, 1, 'fold'),
              ActionEntry(0, 2, 'fold'),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf10_12',
        title: 'BTN KJo push call',
        hand: HandData(
          heroCards: 'Kh Jd',
          position: HeroPosition.btn,
          heroIndex: 0,
          playerCount: 3,
          stacks: {'0': 10, '1': 10, '2': 10},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 10, ev: 0.5),
              ActionEntry(0, 1, 'fold'),
              ActionEntry(0, 2, 'call', amount: 10, ev: 0.5),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf10_13',
        title: 'BTN Q9o fold',
        hand: HandData(
          heroCards: 'Qd 9c',
          position: HeroPosition.btn,
          heroIndex: 0,
          playerCount: 3,
          stacks: {'0': 10, '1': 10, '2': 10},
          actions: {
            0: [ActionEntry(0, 0, 'fold', ev: 0.0)]
          },
        ),
      ),
    ],
  );

  static Future<TrainingPackTemplate> generateFromPreset(
      TrainingPackPreset preset) {
    return PackGeneratorService.generatePackFromPreset(preset);
  }

  static TrainingPackTemplate starterPushfold10bb([BuildContext? context]) {
    if (context == null) return _starterPushfold10bb;
    return _starterPushfold10bb.copyWith(
      name: AppLocalizations.of(context)!.packPushFold10,
    );
  }

  static List<TrainingPackTemplate> getAllTemplates([
    BuildContext? context,
    List<TrainingPackTemplate> user = const [],
  ]) => [...user, starterPushfold10bb(context)];
}
