import '../models/board_filtering_tag.dart';

class BoardFilteringTagLibraryService {
  static final List<BoardFilteringTag> _tags = [
    BoardFilteringTag(
      id: 'aceHigh',
      description: 'Boards with A-high',
      aliases: ['acehigh', 'ace_high'],
      exampleBoards: ['As Kd 3c', 'Ah 7s 2d'],
    ),
    BoardFilteringTag(
      id: 'rainbow',
      description: 'Three different suits',
      aliases: ['rbw'],
      exampleBoards: ['As Kd 3c'],
    ),
    BoardFilteringTag(
      id: 'twoTone',
      description: 'Two suits present',
      aliases: ['twotone', 'two-tone', 'two_tone'],
      exampleBoards: ['As Kd 3d'],
    ),
    BoardFilteringTag(
      id: 'monotone',
      description: 'All cards of the same suit',
      aliases: ['mono'],
      exampleBoards: ['Ah 7h 2h'],
    ),
    BoardFilteringTag(
      id: 'paired',
      description: 'Flop contains a pair',
      aliases: ['pair'],
      exampleBoards: ['Ah As 7c'],
    ),
    BoardFilteringTag(
      id: 'low',
      description: 'Max rank ≤ 9',
      aliases: ['lowboard', 'low_board'],
      exampleBoards: ['2h 5c 9d'],
    ),
    BoardFilteringTag(
      id: 'highCard',
      description: 'Contains at least one card Ten or higher',
      aliases: ['highcard', 'high_card'],
      exampleBoards: ['Kd 7c 2h', 'Th 5s 2d'],
    ),
    BoardFilteringTag(
      id: 'connected',
      description: 'Straight draw heavy',
      aliases: ['straightdrawheavy', 'coordinated'],
      exampleBoards: ['7c 8d 9h'],
    ),
    BoardFilteringTag(
      id: 'broadway',
      description: 'All cards Ten or higher',
      exampleBoards: ['Qs Jh Td'],
      aliases: [],
    ),
    BoardFilteringTag(
      id: 'wet',
      description: 'Draw-heavy board with many possibilities',
      aliases: ['dynamic', 'coordinated', 'drawy'],
      exampleBoards: ['9c Tc Jc'],
    ),
    BoardFilteringTag(
      id: 'dry',
      description: 'Static board lacking draws',
      aliases: [],
      exampleBoards: ['As 7d 2c'],
    ),
    BoardFilteringTag(
      id: 'dynamic',
      description: 'Boards that can change drastically on later streets',
      aliases: [],
      exampleBoards: ['7c 8d Ts'],
    ),
  ];

  static List<BoardFilteringTag> get allTags => List.unmodifiable(_tags);

  static BoardFilteringTag? resolve(String tagIdOrAlias) {
    final key = tagIdOrAlias.toLowerCase();
    for (final t in _tags) {
      if (t.id.toLowerCase() == key) return t;
      if (t.aliases.any((a) => a.toLowerCase() == key)) return t;
    }
    return null;
  }

  static List<String> get supportedTagIds => [for (final t in _tags) t.id];
}
