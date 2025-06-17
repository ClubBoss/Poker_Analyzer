import 'package:test/test.dart';
import 'package:poker_ai_analyzer/import_export/converter_pipeline.dart';
import 'package:poker_ai_analyzer/plugins/converter_registry.dart';
import 'package:poker_ai_analyzer/plugins/converter_plugin.dart';
import 'package:poker_ai_analyzer/plugins/converter_info.dart';
import 'package:poker_ai_analyzer/models/saved_hand.dart';
import 'package:poker_ai_analyzer/models/card_model.dart';
import 'package:poker_ai_analyzer/models/action_entry.dart';
import 'package:poker_ai_analyzer/models/player_model.dart';

class _MockConverter implements ConverterPlugin {
  _MockConverter(this.formatId, this.description);

  @override
  final String formatId;
  @override
  final String description;

  SavedHand? importResult;
  String? exportResult;
  String? validationResult;

  @override
  SavedHand? convertFrom(String externalData) => importResult;

  @override
  String? convertTo(SavedHand hand) => exportResult;

  @override
  String? validate(SavedHand hand) => validationResult;
}

SavedHand _dummyHand() {
  return SavedHand(
    name: 'Test',
    heroIndex: 0,
    heroPosition: 'BTN',
    numberOfPlayers: 2,
    playerCards: <List<CardModel>>[
      <CardModel>[CardModel(rank: 'A', suit: '♠'), CardModel(rank: 'K', suit: '♦')],
      <CardModel>[],
    ],
    boardCards: <CardModel>[],
    boardStreet: 0,
    actions: <ActionEntry>[ActionEntry(0, 0, 'call')],
    stackSizes: <int, int>{0: 100, 1: 100},
    playerPositions: <int, String>{0: 'BTN', 1: 'BB'},
    playerTypes: <int, PlayerType>{0: PlayerType.unknown, 1: PlayerType.unknown},
  );
}

void main() {
  group('ConverterPipeline', () {
    test('delegates import to registry', () {
      final registry = ConverterRegistry();
      final converter = _MockConverter('fmt', 'Format')..importResult = _dummyHand();
      registry.register(converter);

      final pipeline = ConverterPipeline(registry);
      expect(pipeline.tryImport('fmt', 'data'), same(converter.importResult));
    });

    test('delegates export to registry', () {
      final registry = ConverterRegistry();
      final converter = _MockConverter('fmt', 'Format')..exportResult = 'out';
      registry.register(converter);

      final pipeline = ConverterPipeline(registry);
      expect(pipeline.tryExport(_dummyHand(), 'fmt'), 'out');
    });

    test('delegates validation to registry', () {
      final registry = ConverterRegistry();
      final converter = _MockConverter('fmt', 'Format')..validationResult = 'err';
      registry.register(converter);

      final pipeline = ConverterPipeline(registry);
      expect(pipeline.validateForExport(_dummyHand(), 'fmt'), 'err');
    });

    test('provides converter metadata via availableConverters', () {
      final registry = ConverterRegistry();
      registry.register(_MockConverter('fmt', 'Desc'));

      final pipeline = ConverterPipeline(registry);
      final list = pipeline.availableConverters();
      expect(list, hasLength(1));
      expect(list.first.formatId, 'fmt');
      expect(list.first.description, 'Desc');
    });
  });
}
