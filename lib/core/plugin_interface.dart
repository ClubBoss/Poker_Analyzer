import '../services/service_registry.dart';

abstract class PluginInterface {
  void register(ServiceRegistry registry);
  void unregister(ServiceRegistry registry) {}
}
