import 'package:poker_ai_analyzer/plugins/plugin_manager.dart';
import 'package:poker_ai_analyzer/plugins/sample_logging_plugin.dart';
import 'package:poker_ai_analyzer/services/service_registry.dart';

/// Dumps a list of service types currently registered in a [ServiceRegistry].
///
/// This utility can be used during plugin debugging to verify that services
/// are wired up correctly. It loads any built-in plugins and prints the
/// resulting service registry contents.
void main() {
  final ServiceRegistry registry = ServiceRegistry();
  final PluginManager manager = PluginManager();

  // Load built-in plugins here. Additional plugins can be added as needed.
  manager.load(SampleLoggingPlugin());

  // Initialize plugins, allowing them to register services and extensions.
  manager.initializeAll(registry);

  final List<Type> services = registry.dumpAll();
  print('Registered services (${services.length}):');
  for (final Type type in services) {
    print(' - $type');
  }
}
