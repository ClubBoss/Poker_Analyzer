import 'package:poker_ai_analyzer/plugins/converter_plugin.dart';
import 'package:poker_ai_analyzer/plugins/converter_registry.dart';
import 'package:poker_ai_analyzer/plugins/plugin.dart';
import 'package:poker_ai_analyzer/services/service_registry.dart';

/// Plugin that registers provided [ConverterPlugin]s into a shared
/// [ConverterRegistry] stored in the [ServiceRegistry].
class ConverterDiscoveryPlugin implements Plugin {
  /// Creates a plugin that will register the given [converters].
  ConverterDiscoveryPlugin(this._converters);

  final List<ConverterPlugin> _converters;

  @override
  void register(ServiceRegistry registry) {
    // Obtain existing ConverterRegistry or create a new one.
    ConverterRegistry converterRegistry;
    if (registry.contains<ConverterRegistry>()) {
      converterRegistry = registry.get<ConverterRegistry>();
    } else {
      converterRegistry = ConverterRegistry();
      registry.register<ConverterRegistry>(converterRegistry);
    }

    // Register all provided converter plugins.
    for (final ConverterPlugin converter in _converters) {
      converterRegistry.register(converter);
    }
  }
}
