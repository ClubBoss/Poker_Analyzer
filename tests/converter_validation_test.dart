import 'package:test/test.dart';
import 'package:poker_ai_analyzer/plugins/plugin_loader.dart';
import 'package:poker_ai_analyzer/plugins/plugin_manager.dart';
import 'package:poker_ai_analyzer/services/service_registry.dart';
import 'package:poker_ai_analyzer/plugins/converter_registry.dart';
import 'package:poker_ai_analyzer/plugins/converter_plugin.dart';

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
          converterRegistry.findByFormatId(id)!
      ];

      expect(converters, isNotEmpty);

      for (final converter in converters) {
        expect(converter.formatId, isNotEmpty);
        expect(converter.formatId.contains(RegExp(r'\s')), isFalse,
            reason: 'formatId should not contain whitespace');
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
          default:
            sample = '';
        }

        final result = converter.convertFrom(sample);
        expect(result, isNotNull,
            reason: 'converter ${converter.formatId} failed to parse sample');
      }
    });
  });
}
