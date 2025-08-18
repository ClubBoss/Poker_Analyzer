import '../models/game_type.dart';
import '../models/training_pack_template_set.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../core/training/engine/training_type_engine.dart';
import 'training_pack_template_expander_service.dart';
import 'training_pack_template_library_service.dart';

/// Seeds Level II training pack templates based on predefined YAML layouts.
///
/// The seeder expands YAML templates into concrete [TrainingPackTemplateV2]
/// objects using [TrainingPackTemplateExpanderService] and stores them in the
/// in-memory [TrainingPackTemplateLibraryService].
class LevelIIPackTemplateSeeder {
  final TrainingPackTemplateExpanderService _expander;
  final TrainingPackTemplateLibraryService _library;

  const LevelIIPackTemplateSeeder({
    TrainingPackTemplateExpanderService? expander,
    TrainingPackTemplateLibraryService? library,
  }) : _expander = expander ?? TrainingPackTemplateExpanderService(),
       _library = library ?? TrainingPackTemplateLibraryService.instance;

  /// Generates all predefined templates and adds them to the library.
  Future<void> seedAll() async {
    await _seed(
      id: 'l2_open_fold',
      name: 'Open/Fold CO 20bb',
      theme: 'Open Play',
      tags: const ['level2', 'open', 'fold'],
      yaml: _openFoldTemplate,
    );
    await _seed(
      id: 'l2_3bet_push',
      name: '3bet Push SB vs CO',
      theme: '3bet',
      tags: const ['level2', '3bet', 'push'],
      yaml: _threeBetPushTemplate,
    );
    await _seed(
      id: 'l2_vs_3bet_push',
      name: 'Call vs 3bet Push BB',
      theme: '3bet',
      tags: const ['level2', '3bet', 'call'],
      yaml: _vsThreeBetPushTemplate,
    );
  }

  Future<void> _seed({
    required String id,
    required String name,
    required String theme,
    required List<String> tags,
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
      trainingType: TrainingType.pushFold,
      tags: List<String>.from(tags),
      spots: spots,
      spotCount: spots.length,
      created: DateTime.now(),
      gameType: GameType.tournament,
      bb: 20,
      positions: positions.toList(),
      meta: {
        'schemaVersion': '2.0.0',
        'skillLevel': 'intermediate',
        'theme': theme,
      },
    );

    _library.add(tpl);
  }

  // --- YAML templates ---
  static const String _openFoldTemplate = '''
baseSpot:
  id: of_base
  title: CO open AKo
  heroOptions: [open, fold]
  hand:
    heroCards: Ah Kh
    position: co
    heroIndex: 0
    playerCount: 6
    stacks:
      '0': 20
      '1': 20
      '2': 20
      '3': 20
      '4': 20
      '5': 20
''';

  static const String _threeBetPushTemplate = '''
baseSpot:
  id: tb_base
  title: SB shove A5s vs CO open
  villainAction: open 2.5
  heroOptions: [3betPush, fold]
  hand:
    heroCards: As 5s
    position: sb
    heroIndex: 0
    playerCount: 6
    stacks:
      '0': 20
      '1': 20
      '2': 20
      '3': 20
      '4': 20
      '5': 20
''';

  static const String _vsThreeBetPushTemplate = '''
baseSpot:
  id: v3_base
  title: BB calls shove AQo vs SB push
  villainAction: shove
  heroOptions: [call, fold]
  hand:
    heroCards: As Qd
    position: bb
    heroIndex: 0
    playerCount: 6
    stacks:
      '0': 20
      '1': 20
      '2': 20
      '3': 20
      '4': 20
      '5': 20
''';
}
