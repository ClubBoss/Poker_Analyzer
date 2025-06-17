import 'package:test/test.dart';
import 'package:poker_ai_analyzer/import_export/converter_pipeline.dart';
import 'package:poker_ai_analyzer/plugins/converter_registry.dart';
import 'package:poker_ai_analyzer/plugins/converter_plugin.dart';
import 'package:poker_ai_analyzer/models/saved_hand.dart';
import 'package:poker_ai_analyzer/models/card_model.dart';
import 'package:poker_ai_analyzer/models/action_entry.dart';
import 'package:poker_ai_analyzer/models/player_model.dart';

class _MockConverter implements ConverterPlugin {
  _MockConverter(this.formatId, [this.description = 'mock']);

  @override
  final String formatId;
  @override
  final String description;

  SavedHand? importResult;
  String? exportResult;

  @override
  SavedHand? convertFrom(String externalData) => importResult;

  @override
  String? convertTo(SavedHand hand) => exportResult;
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
      final converter = _MockConverter('fmt')..importResult = _dummyHand();
      registry.register(converter);

      final pipeline = ConverterPipeline(registry);
      expect(pipeline.tryImport('fmt', 'data'), same(converter.importResult));
    });

    test('delegates export to registry', () {
      final registry = ConverterRegistry();
      final converter = _MockConverter('fmt')..exportResult = 'out';
      registry.register(converter);

      final pipeline = ConverterPipeline(registry);
      expect(pipeline.tryExport(_dummyHand(), 'fmt'), 'out');
    });

    test('availableConverters returns registry info', () {
      final registry = ConverterRegistry();
      registry.register(_MockConverter('fmt', 'Format')); 

      final pipeline = ConverterPipeline(registry);
      final infos = pipeline.availableConverters();
      expect(infos, hasLength(1));
      expect(infos.first.formatId, 'fmt');
      expect(infos.first.description, 'Format');
    });
  });
}
