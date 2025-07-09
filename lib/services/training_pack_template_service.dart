import '../models/v2/training_pack_preset.dart';
import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/hero_position.dart';
import '../models/game_type.dart';
import '../models/action_entry.dart';
import 'pack_generator_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TrainingPackTemplateService {
  static final TrainingPackTemplate _starterPushfold10bb = TrainingPackTemplate(
    id: 'starter_pushfold_10bb',
    name: 'Push/Fold 10BB (No Ante)',
    gameType: GameType.tournament,
    heroBbStack: 10,
    playerStacksBb: const [10, 10],
    heroPos: HeroPosition.sb,
    tags: const ['starter'],
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
              ActionEntry(0, 0, 'push', amount: 10),
              ActionEntry(0, 1, 'fold'),
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
            0: [ActionEntry(0, 0, 'fold')]
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
              ActionEntry(0, 0, 'push', amount: 10),
              ActionEntry(0, 1, 'call', amount: 9.5),
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
              ActionEntry(0, 0, 'push', amount: 10),
              ActionEntry(0, 1, 'fold'),
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
              ActionEntry(0, 0, 'push', amount: 10),
              ActionEntry(0, 1, 'fold'),
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
              ActionEntry(0, 0, 'push', amount: 10),
              ActionEntry(0, 1, 'fold'),
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
              ActionEntry(0, 0, 'push', amount: 10),
              ActionEntry(0, 1, 'fold'),
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
              ActionEntry(0, 0, 'push', amount: 10),
              ActionEntry(0, 1, 'fold'),
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
            0: [ActionEntry(0, 0, 'fold')]
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
              ActionEntry(0, 0, 'push', amount: 10),
              ActionEntry(0, 1, 'call', amount: 9.5),
            ]
          },
        ),
      ),
      ],
    );

  static TrainingPackTemplate starterPushfold10bb([BuildContext? ctx]) {
    if (ctx == null) return _starterPushfold10bb;
    return _starterPushfold10bb.copyWith(
      name: AppLocalizations.of(ctx)!.packPushFold10,
    );
  }

  static final TrainingPackTemplate _starterPushfold12bb = TrainingPackTemplate(
    id: 'starter_pushfold_12bb',
    name: 'Push/Fold 12BB (No Ante)',
    gameType: GameType.tournament,
    heroBbStack: 12,
    playerStacksBb: const [12, 12],
    heroPos: HeroPosition.sb,
    tags: const ['starter', 'push', '12bb', 'no_ante'],
    difficulty: '1',
    isBuiltIn: true,
    anteBb: 0,
    spots: [
      TrainingPackSpot(
        id: 'pf12_1',
        title: 'AJo push',
        hand: HandData(
          heroCards: 'Ah Jd',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 12, '1': 12},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 12, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf12_2',
        title: 'Q9s push',
        hand: HandData(
          heroCards: 'Qs 9s',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 12, '1': 12},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 12, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf12_3',
        title: 'KTo fold',
        hand: HandData(
          heroCards: 'Kd Td',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 12, '1': 12},
          actions: {
            0: [ActionEntry(0, 0, 'fold', ev: 0.0)]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf12_4',
        title: '66 push call',
        hand: HandData(
          heroCards: '6h 6c',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 12, '1': 12},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 12, ev: 0.5),
              ActionEntry(0, 1, 'call', amount: 12, ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf12_5',
        title: 'T8o fold',
        hand: HandData(
          heroCards: 'Td 8c',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 12, '1': 12},
          actions: {
            0: [ActionEntry(0, 0, 'fold')]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf12_6',
        title: '98s push',
        hand: HandData(
          heroCards: '9h 8h',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 12, '1': 12},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 12, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf12_7',
        title: 'A7s push',
        hand: HandData(
          heroCards: 'Ad 7d',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 12, '1': 12},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 12, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf12_8',
        title: 'A8o push',
        hand: HandData(
          heroCards: 'Ah 8d',
          position: HeroPosition.btn,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 12, '1': 12},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 12, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf12_9',
        title: 'KJs push call',
        hand: HandData(
          heroCards: 'Ks Js',
          position: HeroPosition.btn,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 12, '1': 12},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 12, ev: 0.5),
              ActionEntry(0, 1, 'call', amount: 12, ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf12_10',
        title: 'QTs push',
        hand: HandData(
          heroCards: 'Qd Td',
          position: HeroPosition.btn,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 12, '1': 12},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 12, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf12_11',
        title: 'J9o fold',
        hand: HandData(
          heroCards: 'Jh 9c',
          position: HeroPosition.btn,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 12, '1': 12},
          actions: {
            0: [ActionEntry(0, 0, 'fold')]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf12_12',
        title: '44 push',
        hand: HandData(
          heroCards: '4s 4d',
          position: HeroPosition.btn,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 12, '1': 12},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 12, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf12_13',
        title: 'A5s push',
        hand: HandData(
          heroCards: 'Ac 5c',
          position: HeroPosition.btn,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 12, '1': 12},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 12, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf12_14',
        title: 'KQo push',
        hand: HandData(
          heroCards: 'Kh Qh',
          position: HeroPosition.btn,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 12, '1': 12},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 12, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
    ],
  );

  static TrainingPackTemplate starterPushfold12bb([BuildContext? ctx]) {
    if (ctx == null) return _starterPushfold12bb;
    return _starterPushfold12bb.copyWith(
      name: AppLocalizations.of(ctx)!.packPushFold12,
    );
  }

  static Future<TrainingPackTemplate> generateFromPreset(
      TrainingPackPreset preset) {
    return PackGeneratorService.generatePackFromPreset(preset);
  }

  static List<TrainingPackTemplate> getAllTemplates([BuildContext? ctx]) =>
      [starterPushfold10bb(ctx), starterPushfold12bb(ctx)];
}
