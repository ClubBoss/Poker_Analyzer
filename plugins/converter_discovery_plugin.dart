import 'package:poker_ai_analyzer/services/service_registry.dart';

import 'converter_plugin.dart';
import 'converter_registry.dart';
import 'plugin.dart';

/// Discovery plugin that registers provided [ConverterPlugin]s into a common
/// [ConverterRegistry].
class ConverterDiscoveryPlugin implements Plugin {
  /// Creates the plugin with a list of converter [plugins].
  ConverterDiscoveryPlugin(this.plugins);

  /// Converters to register.
  final List<ConverterPlugin> plugins;

  @override
  void register(ServiceRegistry registry) {
    registry.registerIfAbsent<ConverterRegistry>(ConverterRegistry());
    final ConverterRegistry converterRegistry =
        registry.get<ConverterRegistry>();
    for (final ConverterPlugin plugin in plugins) {
      converterRegistry.register(plugin);
    }
  }
}
