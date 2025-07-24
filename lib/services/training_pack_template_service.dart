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
import 'training_pack_asset_loader.dart';
import 'package:collection/collection.dart';

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

  static final TrainingPackTemplate _starterPushfold15bb = TrainingPackTemplate(
    id: 'starter_pushfold_15bb',
    name: 'Push/Fold 15BB (No Ante)',
    gameType: GameType.tournament,
    heroBbStack: 15,
    playerStacksBb: const [15, 15],
    heroPos: HeroPosition.sb,
    tags: const ['starter', 'push', '15bb', 'no_ante'],
    difficulty: '1',
    isBuiltIn: true,
    anteBb: 0,
    spots: [
      TrainingPackSpot(
        id: 'pf15_1',
        title: 'ATo push',
        hand: HandData(
          heroCards: 'Ah Td',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 15, '1': 15},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 15, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf15_2',
        title: 'K9s push',
        hand: HandData(
          heroCards: 'Kh 9h',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 15, '1': 15},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 15, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf15_3',
        title: 'QJo fold',
        hand: HandData(
          heroCards: 'Qd Jc',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 15, '1': 15},
          actions: {
            0: [ActionEntry(0, 0, 'fold', ev: 0.0)]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf15_4',
        title: '88 push call',
        hand: HandData(
          heroCards: '8s 8c',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 15, '1': 15},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 15, ev: 0.5),
              ActionEntry(0, 1, 'call', amount: 15, ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf15_5',
        title: 'A4s push',
        hand: HandData(
          heroCards: 'Ad 4d',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 15, '1': 15},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 15, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf15_6',
        title: 'JTo fold',
        hand: HandData(
          heroCards: 'Js Td',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 15, '1': 15},
          actions: {
            0: [ActionEntry(0, 0, 'fold', ev: 0.0)]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf15_7',
        title: 'T9s push',
        hand: HandData(
          heroCards: 'Td 9d',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 15, '1': 15},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 15, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf15_8',
        title: 'A9o push',
        hand: HandData(
          heroCards: 'As 9c',
          position: HeroPosition.btn,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 15, '1': 15},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 15, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf15_9',
        title: 'KTs push',
        hand: HandData(
          heroCards: 'Kh Ts',
          position: HeroPosition.btn,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 15, '1': 15},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 15, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf15_10',
        title: 'Q9o fold',
        hand: HandData(
          heroCards: 'Qh 9d',
          position: HeroPosition.btn,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 15, '1': 15},
          actions: {
            0: [ActionEntry(0, 0, 'fold', ev: 0.0)]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf15_11',
        title: '77 push call',
        hand: HandData(
          heroCards: '7s 7d',
          position: HeroPosition.btn,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 15, '1': 15},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 15, ev: 0.5),
              ActionEntry(0, 1, 'call', amount: 15, ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf15_12',
        title: 'A6s push',
        hand: HandData(
          heroCards: 'Ah 6h',
          position: HeroPosition.btn,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 15, '1': 15},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 15, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf15_13',
        title: 'KJo push',
        hand: HandData(
          heroCards: 'Kd Jd',
          position: HeroPosition.btn,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 15, '1': 15},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 15, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf15_14',
        title: 'J9s push',
        hand: HandData(
          heroCards: 'Jh 9h',
          position: HeroPosition.btn,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 15, '1': 15},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 15, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
    ],
  );

  static final TrainingPackTemplate _starterPushfold20bb = TrainingPackTemplate(
    id: 'starter_pushfold_20bb',
    name: 'Push/Fold 20BB (No Ante)',
    gameType: GameType.tournament,
    heroBbStack: 20,
    playerStacksBb: const [20, 20],
    heroPos: HeroPosition.sb,
    tags: const ['starter', 'push', '20bb', 'no_ante'],
    difficulty: '1',
    isBuiltIn: true,
    anteBb: 0,
    spots: [
      TrainingPackSpot(
        id: 'pf20_1',
        title: 'AJo push',
        hand: HandData(
          heroCards: 'Ah Jd',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 20, '1': 20},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 20, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf20_2',
        title: 'KQo push',
        hand: HandData(
          heroCards: 'Kh Qd',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 20, '1': 20},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 20, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf20_3',
        title: 'QJo fold',
        hand: HandData(
          heroCards: 'Qh Jc',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 20, '1': 20},
          actions: {
            0: [ActionEntry(0, 0, 'fold', ev: 0.0)]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf20_4',
        title: '99 push call',
        hand: HandData(
          heroCards: '9c 9d',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 20, '1': 20},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 20, ev: 0.5),
              ActionEntry(0, 1, 'call', amount: 20, ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf20_5',
        title: 'A5s push',
        hand: HandData(
          heroCards: 'As 5s',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 20, '1': 20},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 20, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf20_6',
        title: 'ATo push',
        hand: HandData(
          heroCards: 'Ad Th',
          position: HeroPosition.btn,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 20, '1': 20},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 20, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf20_7',
        title: 'KTs push',
        hand: HandData(
          heroCards: 'Kd Ts',
          position: HeroPosition.btn,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 20, '1': 20},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 20, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf20_8',
        title: 'Q9o fold',
        hand: HandData(
          heroCards: 'Qd 9h',
          position: HeroPosition.btn,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 20, '1': 20},
          actions: {
            0: [ActionEntry(0, 0, 'fold', ev: 0.0)]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf20_9',
        title: '77 push call',
        hand: HandData(
          heroCards: '7s 7d',
          position: HeroPosition.btn,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 20, '1': 20},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 20, ev: 0.5),
              ActionEntry(0, 1, 'call', amount: 20, ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf20_10',
        title: 'A8s push',
        hand: HandData(
          heroCards: 'Ah 8h',
          position: HeroPosition.btn,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 20, '1': 20},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 20, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf20_11',
        title: 'AQo push',
        hand: HandData(
          heroCards: 'Ah Qc',
          position: HeroPosition.co,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 20, '1': 20},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 20, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf20_12',
        title: 'KJs push',
        hand: HandData(
          heroCards: 'Ks Jd',
          position: HeroPosition.co,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 20, '1': 20},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 20, ev: 0.5),
              ActionEntry(0, 1, 'fold', ev: 0.0),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf20_13',
        title: 'T9s fold',
        hand: HandData(
          heroCards: 'Td 9d',
          position: HeroPosition.co,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 20, '1': 20},
          actions: {
            0: [ActionEntry(0, 0, 'fold', ev: 0.0)]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'pf20_14',
        title: '55 push',
        hand: HandData(
          heroCards: '5h 5c',
          position: HeroPosition.co,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': 20, '1': 20},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 20, ev: 0.5),
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

  static TrainingPackTemplate starterPushfold15bb([BuildContext? ctx]) {
    if (ctx == null) return _starterPushfold15bb;
    return _starterPushfold15bb.copyWith(
      name: AppLocalizations.of(ctx)!.packPushFold15,
    );
  }

  static TrainingPackTemplate starterPushfold20bb([BuildContext? ctx]) {
    if (ctx == null) return _starterPushfold20bb;
    return _starterPushfold20bb.copyWith(
      name: AppLocalizations.of(ctx)!.packPushFold20,
    );
  }

  static Future<TrainingPackTemplate> generateFromPreset(
      TrainingPackPreset preset) {
    return PackGeneratorService.generatePackFromPreset(preset);
  }

  static List<TrainingPackTemplate> getAllTemplates([BuildContext? ctx]) =>
      [
        starterPushfold10bb(ctx),
        starterPushfold12bb(ctx),
        starterPushfold15bb(ctx),
        starterPushfold20bb(ctx),
        ...TrainingPackAssetLoader.instance.getAll(),
      ];

  /// Returns `true` if a template with [id] exists.
  static bool hasTemplate(String id) {
    return getAllTemplates().any((t) => t.id == id);
  }

  static TrainingPackTemplate? getById(String id, [BuildContext? ctx]) {
    return getAllTemplates(ctx).firstWhereOrNull((t) => t.id == id);
  }
}
