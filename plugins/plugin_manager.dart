import 'package:poker_ai_analyzer/services/service_registry.dart';

import 'plugin.dart';

/// Manages plug-ins for the Poker Analyzer application.
class PluginManager {
  /// List of loaded plug-ins.
  final List<Plugin> _plugins = <Plugin>[];

  /// Loads a new [plugin].
  void load(Plugin plugin) {
    _plugins.add(plugin);
  }

  /// Initializes all loaded plug-ins using the provided [registry].
  void initializeAll(ServiceRegistry registry) {
    for (final Plugin plugin in _plugins) {
      plugin.register(registry);
    }
  }
}
