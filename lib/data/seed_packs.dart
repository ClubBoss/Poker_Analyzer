import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/hero_position.dart';
import '../models/game_type.dart';
import '../models/action_entry.dart';
import '../services/pack_generator_service.dart';

final TrainingPackTemplate autoPushFold10bb =
    PackGeneratorService.generatePushFoldPackSync(
  id: 'auto_10bb_sb',
  name: 'Auto SB 10bb push/fold',
  heroBbStack: 10,
  playerStacksBb: [10, 10],
  heroPos: HeroPosition.sb,
  heroRange: [
    '22',
    '33',
    'A2s',
    'A3s',
    'K9s',
    'Q9s',
    'J9s',
    'T9s',
    '98s',
    'AJo',
    'KQo',
    'A2o',
    'A3o',
    'A4o',
    'A5o',
    'A6o',
    'A7o',
    'A8o',
    'A9o',
    'ATo',
  ],
);

final List<TrainingPackTemplate> seedPacks = [
  autoPushFold10bb,
  TrainingPackTemplate(
    id: 'sb_vs_bb_10bb',
    name: 'SB vs BB 10bb',
    gameType: GameType.tournament,
    spots: [
      TrainingPackSpot(
        id: 'sb10_1',
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
        id: 'sb10_2',
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
        id: 'sb10_3',
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
        id: 'sb10_4',
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
    ],
  ),
  TrainingPackTemplate(
    id: 'co_vs_btn_12bb',
    name: 'CO vs BTN 12bb',
    gameType: GameType.tournament,
    spots: [
      TrainingPackSpot(
        id: 'co12_1',
        title: 'KJo push',
        hand: HandData(
          heroCards: 'Kh Jd',
          position: HeroPosition.co,
          heroIndex: 0,
          playerCount: 3,
          stacks: {'0': 12, '1': 12, '2': 12},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 12),
              ActionEntry(0, 1, 'fold'),
              ActionEntry(0, 2, 'fold'),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'co12_2',
        title: 'A8s push call',
        hand: HandData(
          heroCards: 'Ah 8h',
          position: HeroPosition.co,
          heroIndex: 0,
          playerCount: 3,
          stacks: {'0': 12, '1': 12, '2': 12},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 12),
              ActionEntry(0, 1, 'fold'),
              ActionEntry(0, 2, 'call', amount: 11.5),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'co12_3',
        title: '55 push',
        hand: HandData(
          heroCards: '5s 5d',
          position: HeroPosition.co,
          heroIndex: 0,
          playerCount: 3,
          stacks: {'0': 12, '1': 12, '2': 12},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 12),
              ActionEntry(0, 1, 'fold'),
              ActionEntry(0, 2, 'fold'),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'co12_4',
        title: 'JTo fold',
        hand: HandData(
          heroCards: 'Jh Td',
          position: HeroPosition.co,
          heroIndex: 0,
          playerCount: 3,
          stacks: {'0': 12, '1': 12, '2': 12},
          actions: {
            0: [ActionEntry(0, 0, 'fold')]
          },
        ),
      ),
    ],
  ),
  TrainingPackTemplate(
    id: 'hj_vs_table_8bb',
    name: 'HJ vs Table 8bb',
    gameType: GameType.tournament,
    spots: [
      TrainingPackSpot(
        id: 'hj8_1',
        title: 'A5s push call',
        hand: HandData(
          heroCards: 'Ad 5d',
          position: HeroPosition.mp,
          heroIndex: 0,
          playerCount: 6,
          stacks: {
            '0': 8,
            '1': 8,
            '2': 8,
            '3': 8,
            '4': 8,
            '5': 8
          },
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 8),
              ActionEntry(0, 1, 'fold'),
              ActionEntry(0, 2, 'fold'),
              ActionEntry(0, 3, 'fold'),
              ActionEntry(0, 4, 'call', amount: 7.5),
              ActionEntry(0, 5, 'fold'),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'hj8_2',
        title: '77 push',
        hand: HandData(
          heroCards: '7h 7c',
          position: HeroPosition.mp,
          heroIndex: 0,
          playerCount: 6,
          stacks: {
            '0': 8,
            '1': 8,
            '2': 8,
            '3': 8,
            '4': 8,
            '5': 8
          },
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 8),
              ActionEntry(0, 1, 'fold'),
              ActionEntry(0, 2, 'fold'),
              ActionEntry(0, 3, 'fold'),
              ActionEntry(0, 4, 'fold'),
              ActionEntry(0, 5, 'fold'),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'hj8_3',
        title: 'KQs push',
        hand: HandData(
          heroCards: 'Ks Qs',
          position: HeroPosition.mp,
          heroIndex: 0,
          playerCount: 6,
          stacks: {
            '0': 8,
            '1': 8,
            '2': 8,
            '3': 8,
            '4': 8,
            '5': 8
          },
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 8),
              ActionEntry(0, 1, 'fold'),
              ActionEntry(0, 2, 'fold'),
              ActionEntry(0, 3, 'fold'),
              ActionEntry(0, 4, 'fold'),
              ActionEntry(0, 5, 'fold'),
            ]
          },
        ),
      ),
      TrainingPackSpot(
        id: 'hj8_4',
        title: 'T9s fold',
        hand: HandData(
          heroCards: 'Td 9d',
          position: HeroPosition.mp,
          heroIndex: 0,
          playerCount: 6,
          stacks: {
            '0': 8,
            '1': 8,
            '2': 8,
            '3': 8,
            '4': 8,
            '5': 8
          },
          actions: {
            0: [ActionEntry(0, 0, 'fold')]
          },
        ),
      ),
    ],
  ),
];
