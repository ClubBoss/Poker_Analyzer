import 'package:test/test.dart';
import 'package:poker_analyzer/plugins/plugin_loader.dart';
import 'package:poker_analyzer/plugins/plugin_manager.dart';
import 'package:poker_analyzer/services/service_registry.dart';
import 'package:poker_analyzer/plugins/converter_registry.dart';
import 'package:poker_analyzer/plugins/converter_plugin.dart';

void main() {
  group('Converter validation', () {
    test('built-in converters have valid metadata and basic functionality', () {
      final loader = PluginLoader();
      final manager = PluginManager();
      final registry = ServiceRegistry();

      for (final plugin in loader.loadBuiltInPlugins()) {
        manager.load(plugin);
      }
      manager.initializeAll(registry);

      final converterRegistry = registry.get<ConverterRegistry>();
      final converters = <ConverterPlugin>[
        for (final id in converterRegistry.dumpFormatIds())
          converterRegistry.findByFormatId(id)!,
      ];

      expect(converters, isNotEmpty);

      for (final converter in converters) {
        expect(converter.formatId, isNotEmpty);
        expect(
          converter.formatId.contains(RegExp(r'\s')),
          isFalse,
          reason: 'formatId should not contain whitespace',
        );
        expect(converter.description.trim(), isNotEmpty);
        expect(converter.capabilities, isNotNull);

        String sample;
        switch (converter.formatId) {
          case 'poker_analyzer_json':
            sample = '{}';
            break;
          case 'simple_hand_history':
            sample = 'hand\ntable\n1\n';
            break;
          case 'pokerstars_hand_history':
            sample = [
              'PokerStars Hand #1: Hold\'em No Limit (\$0.01/\$0.02 USD) - 2023/01/01 00:00:00 ET',
              'Table \u0027Alpha\u0027 6-max Seat #1 is the button',
              'Seat 1: Player1 (\$1 in chips)',
              'Seat 2: Player2 (\$1 in chips)',
            ].join('\n');
            break;
          case 'ggpoker_hand_history':
            sample = [
              'Hand #1 - Holdem NL (0.01/0.02)',
              "Table 'Alpha' 6-max",
              'Seat 1: P1 (1)',
              'Seat 2: P2 (1)',
            ].join('\n');
            break;
          case 'partypoker_hand_history':
            sample = [
              'PartyPoker Hand #1',
              'Seat 1: Hero (1)',
              'Seat 2: Villain (1)',
              '*** HOLE CARDS ***',
              'Dealt to Hero [Ah Kh]',
              'Hero raises 2 to 2',
              'Villain folds',
            ].join('\n');
            break;
          case 'wpn_hand_history':
            sample = [
              'Winning Poker Network Hand #1',
              'Seat 1: Hero (1)',
              'Seat 2: Villain (1)',
              '*** HOLE CARDS ***',
              'Dealt to Hero [Ah Kh]',
              'Hero raises to 2',
              'Villain folds',
            ].join('\n');
            break;
          case 'winamax_hand_history':
            sample = [
              'Winamax Poker - Tournament',
              'Seat 1: Hero (1500)',
              'Seat 2: Villain (1500)',
              '** HOLE CARDS **',
              'Dealt to Hero [Ah Kh]',
              'Hero raises 3 to 3',
              'Villain folds',
            ].join('\n');
            break;
          case '888poker_hand_history':
            sample = [
              '888poker Hand #1',
              'Seat 1: Hero (1)',
              'Seat 2: Villain (1)',
              '*** HOLE CARDS ***',
              'Dealt to Hero [Ah Kh]',
              'Hero raises to 2',
              'Villain folds',
            ].join('\n');
            break;
          case 'ipoker_hand_history':
            sample = [
              'iPoker Hand #1',
              'Seat 1: Hero (1)',
              'Seat 2: Villain (1)',
              '*** HOLE CARDS ***',
              'Dealt to Hero [Ah Kh]',
              'Hero raises to 2',
              'Villain folds',
            ].join('\n');
            break;
          default:
            sample = '';
        }

        final result = converter.convertFrom(sample);
        expect(
          result,
          isNotNull,
          reason: 'converter ${converter.formatId} failed to parse sample',
        );
      }
    });
  });
}
