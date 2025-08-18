import 'package:test/test.dart';
import 'package:poker_analyzer/plugins/converter_discovery_plugin.dart';
import 'package:poker_analyzer/plugins/converter_plugin.dart';
import 'package:poker_analyzer/plugins/converter_registry.dart';
import 'package:poker_analyzer/plugins/plugin_manager.dart';
import 'package:poker_analyzer/plugins/plugin_loader.dart';
import 'package:poker_analyzer/services/service_registry.dart';
import 'package:poker_analyzer/models/saved_hand.dart';

class _DummyConverter implements ConverterPlugin {
  _DummyConverter(this.id);

  final String id;

  @override
  String get formatId => id;

  @override
  SavedHand? convertFrom(String externalData) => null;

  @override
  String? validate(SavedHand hand) => null;
}

void main() {
  group('ConverterDiscoveryPlugin', () {
    test('aggregates converters from multiple plugins', () {
      final registry = ServiceRegistry();
      final manager = PluginManager();
      manager.load(
        ConverterDiscoveryPlugin(<ConverterPlugin>[_DummyConverter('a')]),
      );
      manager.load(
        ConverterDiscoveryPlugin(<ConverterPlugin>[_DummyConverter('b')]),
      );

      manager.initializeAll(registry);

      final converterRegistry = registry.get<ConverterRegistry>();
      expect(converterRegistry.findByFormatId('a'), isNotNull);
      expect(converterRegistry.findByFormatId('b'), isNotNull);
    });

    test('built-in plugins register converters', () {
      final loader = PluginLoader();
      final manager = PluginManager();
      final registry = ServiceRegistry();

      for (final plugin in loader.loadBuiltInPlugins()) {
        manager.load(plugin);
      }
      manager.initializeAll(registry);

      final converterRegistry = registry.get<ConverterRegistry>();
      final converters = converterRegistry.dumpConverters();
      expect(converters, isNotEmpty);

      for (final info in converters) {
        expect(info.formatId.trim(), isNotEmpty);
        expect(info.description.trim(), isNotEmpty);
      }
    });
  });
}
