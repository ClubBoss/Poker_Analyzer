import 'package:poker_ai_analyzer/services/service_registry.dart';

import 'service_extension.dart';

/// Base interface for Poker Analyzer plug-ins.
///
/// Plug-ins register their services through the provided [ServiceRegistry].
abstract class Plugin {
  /// Registers services into the given [registry].
  void register(ServiceRegistry registry);

  /// Additional service extensions provided by the plug-in.
  List<ServiceExtension<dynamic>> get extensions => <ServiceExtension<dynamic>>[];
}
