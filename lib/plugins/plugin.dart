import 'package:poker_analyzer/services/service_registry.dart';
import 'package:poker_analyzer/core/plugin_interface.dart';

import 'service_extension.dart';

/// Base interface for Poker Analyzer plug-ins.
///
/// Plug-ins register their services through the provided [ServiceRegistry].
abstract class Plugin implements PluginInterface {
  /// Registers services into the given [registry].
  @override
  void register(ServiceRegistry registry);

  /// Additional service extensions provided by the plug-in.
  @override
  List<ServiceExtension<dynamic>> get extensions => <ServiceExtension<dynamic>>[];

  @override
  void unregister(ServiceRegistry registry) {}
}
