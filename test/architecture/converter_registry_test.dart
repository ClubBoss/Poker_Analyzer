import 'package:test/test.dart';
import 'package:poker_analyzer/plugins/converter_registry.dart';
import 'package:poker_analyzer/plugins/converter_plugin.dart';
import 'package:poker_analyzer/plugins/converter_format_capabilities.dart';
import 'package:poker_analyzer/models/saved_hand.dart';
import 'package:poker_analyzer/models/card_model.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/models/player_model.dart';

class _MockConverter implements ConverterPlugin {
  _MockConverter(
    this.formatId,
    this.description, [
    this.onConvertFrom,
    this.onConvertTo,
    this.onValidate,
    this.capabilities = const ConverterFormatCapabilities(
      supportsImport: true,
      supportsExport: true,
      requiresBoard: false,
      supportsMultiStreet: true,
    ),
  ]);

  @override
  final String formatId;
  @override
  final String description;

  @override
  final ConverterFormatCapabilities capabilities;

  final SavedHand? Function(String data)? onConvertFrom;
  final String? Function(SavedHand hand)? onConvertTo;
  final String? Function(SavedHand hand)? onValidate;

  @override
  SavedHand? convertFrom(String externalData) =>
      onConvertFrom != null ? onConvertFrom!(externalData) : null;

  @override
  String? convertTo(SavedHand hand) =>
      onConvertTo != null ? onConvertTo!(hand) : null;

  @override
  String? validate(SavedHand hand) =>
      onValidate != null ? onValidate!(hand) : null;
}

SavedHand _dummyHand() {
  return SavedHand(
    name: 'Test',
    heroIndex: 0,
    heroPosition: 'BTN',
    numberOfPlayers: 2,
    playerCards: <List<CardModel>>[
      <CardModel>[
        CardModel(rank: 'A', suit: '♠'),
        CardModel(rank: 'K', suit: '♦'),
      ],
      <CardModel>[],
    ],
    boardCards: <CardModel>[],
    boardStreet: 0,
    actions: <ActionEntry>[ActionEntry(0, 0, 'call')],
    stackSizes: <int, int>{0: 100, 1: 100},
    playerPositions: <int, String>{0: 'BTN', 1: 'BB'},
    playerTypes: <int, PlayerType>{
      0: PlayerType.unknown,
      1: PlayerType.unknown,
    },
  );
}

void main() {
  group('ConverterRegistry', () {
    test('registers converter plugins', () {
      final registry = ConverterRegistry();
      final plugin = _MockConverter('foo', 'Foo converter');
      registry.register(plugin);

      expect(registry.findByFormatId('foo'), same(plugin));
    });

    test('rejects duplicate format ids', () {
      final registry = ConverterRegistry();
      registry.register(_MockConverter('dup', 'D'));

      expect(
        () => registry.register(_MockConverter('dup', 'D')),
        throwsStateError,
      );
    });

    test('findByFormatId returns the correct plugin', () {
      final registry = ConverterRegistry();
      final first = _MockConverter('a', 'A');
      final second = _MockConverter('b', 'B');
      registry.register(first);
      registry.register(second);

      expect(registry.findByFormatId('b'), same(second));
      expect(registry.findByFormatId('c'), isNull);
    });

    test('tryConvert returns result on success', () {
      final hand = _dummyHand();
      final registry = ConverterRegistry();
      registry.register(_MockConverter('ok', 'Ok', (_) => hand));

      final result = registry.tryConvert('ok', 'data');
      expect(result, same(hand));
    });

    test('tryConvert returns null on failure or missing plugin', () {
      final registry = ConverterRegistry();
      registry.register(_MockConverter('fail', 'Fail'));

      expect(registry.tryConvert('fail', 'data'), isNull);
      expect(registry.tryConvert('missing', 'data'), isNull);
    });

    test('tryExport returns result on success', () {
      final registry = ConverterRegistry();
      registry.register(_MockConverter('ok', 'Ok', null, (_) => 'exported'));

      final result = registry.tryExport('ok', _dummyHand());
      expect(result, 'exported');
    });

    test('tryExport returns null on failure or missing plugin', () {
      final registry = ConverterRegistry();
      registry.register(_MockConverter('fail', 'Fail'));

      expect(registry.tryExport('fail', _dummyHand()), isNull);
      expect(registry.tryExport('missing', _dummyHand()), isNull);
    });

    test('validateForExport forwards validation', () {
      final registry = ConverterRegistry();
      registry.register(_MockConverter('fmt', 'Fmt', null, null, (_) => 'bad'));

      expect(registry.validateForExport('fmt', _dummyHand()), 'bad');
    });

    test('validateForExport returns null for success or missing plugin', () {
      final registry = ConverterRegistry();
      registry.register(_MockConverter('ok', 'Ok', null, null, (_) => null));

      expect(registry.validateForExport('ok', _dummyHand()), isNull);
      expect(registry.validateForExport('missing', _dummyHand()), isNull);
    });

    test('dumpConverters returns converter metadata', () {
      final registry = ConverterRegistry();
      registry.register(_MockConverter('fmt', 'Test fmt'));

      final converters = registry.dumpConverters();
      expect(converters, hasLength(1));
      expect(converters.first.formatId, 'fmt');
      expect(converters.first.description, 'Test fmt');
      expect(converters.first.capabilities.supportsExport, isTrue);
    });

    test('queryConverters filters by capability flags', () {
      final registry = ConverterRegistry();
      registry.register(
        _MockConverter(
          'import_only',
          'Import Only',
          null,
          null,
          null,
          const ConverterFormatCapabilities(
            supportsImport: true,
            supportsExport: false,
            requiresBoard: false,
            supportsMultiStreet: true,
          ),
        ),
      );
      registry.register(
        _MockConverter(
          'export_only',
          'Export Only',
          null,
          null,
          null,
          const ConverterFormatCapabilities(
            supportsImport: false,
            supportsExport: true,
            requiresBoard: false,
            supportsMultiStreet: true,
          ),
        ),
      );

      final importConverters = registry.queryConverters(
        supportsImport: true,
        supportsExport: false,
      );
      expect(importConverters, hasLength(1));
      expect(importConverters.first.formatId, 'import_only');

      final exportConverters = registry.queryConverters(
        supportsExport: true,
        supportsImport: false,
      );
      expect(exportConverters, hasLength(1));
      expect(exportConverters.first.formatId, 'export_only');
    });

    test('detectCompatible finds matching converter', () {
      final registry = ConverterRegistry();
      final ok = _MockConverter(
        'ok',
        'Ok',
        (d) => d == 'match' ? _dummyHand() : null,
      );
      registry.register(ok);
      registry.register(_MockConverter('bad', 'Bad'));

      final result = registry.detectCompatible('match');
      expect(result, same(ok));
    });

    test('detectCompatible returns null when none match', () {
      final registry = ConverterRegistry();
      registry.register(_MockConverter('a', 'A'));

      final result = registry.detectCompatible('data');
      expect(result, isNull);
    });
  });
}
