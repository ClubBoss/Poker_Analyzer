import 'package:poker_ai_analyzer/services/service_registry.dart';

/// Base class for plugin-provided service extensions.
///
/// Extensions can override or provide additional service implementations.
abstract class ServiceExtension<T> {
  const ServiceExtension();

  /// Creates an instance of [T] using the provided [registry].
  T create(ServiceRegistry registry);

  /// Registers the created service into the [registry].
  void register(ServiceRegistry registry) {
    registry.register<T>(create(registry));
  }
}
