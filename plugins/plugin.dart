import 'package:poker_ai_analyzer/services/service_registry.dart';

/// Base interface for Poker Analyzer plug-ins.
///
/// Plug-ins register their services through the provided [ServiceRegistry].
abstract class Plugin {
  /// Registers services into the given [registry].
  void register(ServiceRegistry registry);
}
