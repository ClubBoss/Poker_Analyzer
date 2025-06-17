import 'package:test/test.dart';
import 'package:poker_ai_analyzer/plugins/converter_discovery_plugin.dart';
import 'package:poker_ai_analyzer/plugins/converter_plugin.dart';
import 'package:poker_ai_analyzer/plugins/converter_registry.dart';
import 'package:poker_ai_analyzer/services/service_registry.dart';
import 'package:poker_ai_analyzer/models/saved_hand.dart';

class DummyConverter implements ConverterPlugin {
  DummyConverter(this.formatId);

  @override
  final String formatId;

  @override
  SavedHand? convertFrom(String externalData) => null;
}

void main() {
  group('ConverterDiscoveryPlugin', () {
    test('registers converters into shared registry', () {
      final registry = ServiceRegistry();
      final converterA = DummyConverter('A');
      final converterB = DummyConverter('B');
      final pluginA = ConverterDiscoveryPlugin(<ConverterPlugin>[converterA]);
      final pluginB = ConverterDiscoveryPlugin(<ConverterPlugin>[converterB]);

      pluginA.register(registry);
      pluginB.register(registry);

      final ConverterRegistry convRegistry = registry.get<ConverterRegistry>();
      expect(convRegistry.findByFormatId('A'), same(converterA));
      expect(convRegistry.findByFormatId('B'), same(converterB));
    });
  });
}
