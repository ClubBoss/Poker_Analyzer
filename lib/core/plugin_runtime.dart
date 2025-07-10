import '../services/service_registry.dart';
import '../plugins/plugin_loader.dart';
import '../plugins/plugin_manager.dart';

class PluginRuntime {
  PluginRuntime();

  final ServiceRegistry registry = ServiceRegistry();
  final PluginManager _manager = PluginManager();
  final PluginLoader _loader = PluginLoader();

  Future<void> initialize() async {
    await _loader.loadAll(registry, _manager);
  }
}
