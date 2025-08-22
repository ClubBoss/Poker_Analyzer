import '../models/game_type.dart';
import '../models/training_pack_template_set.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../core/training/engine/training_type_engine.dart';
import 'training_pack_template_expander_service.dart';
import 'training_pack_template_library_service.dart';

/// Seeds postflop training pack templates for flop, turn and river scenarios.
///
/// Templates are defined via YAML and expanded into concrete
/// [TrainingPackTemplateV2] objects using
/// [TrainingPackTemplateExpanderService]. Generated templates are stored in
/// the in-memory [TrainingPackTemplateLibraryService]. Board generation relies
/// on [FullBoardGeneratorV2] under the hood via the expander service.
class PostflopTemplateSeeder {
  final TrainingPackTemplateExpanderService _expander;
  final TrainingPackTemplateLibraryService _library;

  PostflopTemplateSeeder({
    TrainingPackTemplateExpanderService? expander,
    TrainingPackTemplateLibraryService? library,
  }) : _expander = expander ?? TrainingPackTemplateExpanderService(),
       _library = library ?? TrainingPackTemplateLibraryService.instance;

  /// Seeds all predefined postflop templates.
  Future<void> seedAll() async {
    await _seed(
      id: 'pf_flop_cbet',
      name: 'Flop C-Bet Template',
      yaml: _flopCbetTemplate,
    );
    await _seed(
      id: 'pf_turn_barrel',
      name: 'Turn Barrel Template',
      yaml: _turnBarrelTemplate,
    );
    await _seed(
      id: 'pf_river_decision',
      name: 'River Decision Template',
      yaml: _riverDecisionTemplate,
    );
  }

  Future<void> _seed({
    required String id,
    required String name,
    required String yaml,
  }) async {
    if (_library.getById(id) != null) return;

    final set = TrainingPackTemplateSet.fromYaml(yaml);
    final spots = _expander.expand(set);
    final positions = <String>{for (final s in spots) s.hand.position.name};

    final tpl = TrainingPackTemplateV2(
      id: id,
      name: name,
      description: name,
      trainingType: TrainingType.postflop,
      tags: const ['flop', 'turn', 'river', 'barrel', 'bet', 'check'],
      spots: spots,
      spotCount: spots.length,
      created: DateTime.now(),
      gameType: GameType.tournament,
      bb: 100,
      positions: positions.toList(),
      meta: const {
        'schemaVersion': '2.0.0',
        'skillLevel': 'advanced',
        'theme': 'Postflop Play',
      },
    );

    _library.add(tpl);
  }

  // --- YAML templates ---
  static const String _flopCbetTemplate = '''
baseSpot:
  id: flop_cbet_base
  title: Flop C-Bet
  heroOptions: [bet, check]
  hand:
    heroCards: Ah Kh
    position: btn
    heroIndex: 0
    playerCount: 2
    stacks:
      '0': 100
      '1': 100
  tags: [postflop, flop]
variations:
  - targetStreet: flop
    boardConstraints:
      - targetStreet: flop
        requiredTextures: [dry, low, paired]
    linePattern:
      streets:
        preflop: [villainRaise, call]
        flop: [bet]
''';

  static const String _turnBarrelTemplate = '''
baseSpot:
  id: turn_barrel_base
  title: Turn Barrel
  heroOptions: [barrel, check]
  hand:
    heroCards: Ad Qd
    position: btn
    heroIndex: 0
    playerCount: 2
    stacks:
      '0': 100
      '1': 100
  tags: [postflop, turn]
variations:
  - targetStreet: turn
    boardConstraints:
      - targetStreet: turn
        requiredTextures: [connected, low]
    linePattern:
      streets:
        flop: [bet, villainCall]
        turn: [bet]
''';

  static const String _riverDecisionTemplate = '''
baseSpot:
  id: river_decision_base
  title: River Decision
  heroOptions: [valueBet, bluff, check]
  hand:
    heroCards: As Kd
    position: btn
    heroIndex: 0
    playerCount: 2
    stacks:
      '0': 100
      '1': 100
  tags: [postflop, river]
variations:
  - targetStreet: river
    boardConstraints:
      - targetStreet: river
        requiredTextures: [broadway, rainbow]
    linePattern:
      streets:
        flop: [bet, villainCall]
        turn: [bet, villainCall]
        river: [bet]
''';
}
