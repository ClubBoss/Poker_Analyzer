import 'package:test/test.dart';
import 'package:poker_analyzer/plugins/plugin_loader.dart';
import 'package:poker_analyzer/plugins/plugin_manager.dart';
import 'package:poker_analyzer/services/service_registry.dart';
import 'package:poker_analyzer/plugins/converter_registry.dart';

void main() {
  group('PartyPoker and WPN converters', () {
    test('import and export pipeline', () {
      final loader = PluginLoader();
      final manager = PluginManager();
      final registry = ServiceRegistry();
      for (final plugin in loader.loadBuiltInPlugins()) {
        manager.load(plugin);
      }
      manager.initializeAll(registry);
      final converterRegistry = registry.get<ConverterRegistry>();
      final party = converterRegistry.findByFormatId('partypoker_hand_history');
      final wpn = converterRegistry.findByFormatId('wpn_hand_history');
      expect(party, isNotNull);
      expect(wpn, isNotNull);
      final partySample = [
        'PartyPoker Hand #1',
        'Seat 1: Hero (1)',
        'Seat 2: Villain (1)',
        '*** HOLE CARDS ***',
        'Dealt to Hero [Ah Kh]',
        'Hero raises 2 to 2',
        'Villain folds',
      ].join('\n');
      final wpnSample = [
        'Winning Poker Network Hand #1',
        'Seat 1: Hero (1)',
        'Seat 2: Villain (1)',
        '*** HOLE CARDS ***',
        'Dealt to Hero [Ah Kh]',
        'Hero raises to 2',
        'Villain folds',
      ].join('\n');
      final partyHand = party!.convertFrom(partySample);
      final wpnHand = wpn!.convertFrom(wpnSample);
      expect(partyHand, isNotNull);
      expect(wpnHand, isNotNull);
      expect(converterRegistry.tryExport('partypoker_hand_history', partyHand!), isNull);
      expect(converterRegistry.tryExport('wpn_hand_history', wpnHand!), isNull);
    });
  });
}
