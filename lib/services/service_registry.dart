
/// Centralized registry for application services.
///
/// Services are registered and looked up by their runtime type. Attempts to
/// register the same type twice or retrieve an unregistered service will throw
/// a [StateError].
class ServiceRegistry {
  final Map<Type, Object> _services = <Type, Object>{};

  /// Registers [service] for type [T].
  /// Throws a [StateError] if a service of this type is already registered.
  void register<T>(T service) {
    final Type type = T;
    if (_services.containsKey(type)) {
      throw StateError('Service of type $T is already registered');
    }
    _services[type] = service as Object;
  }

  /// Returns the registered service for type [T].
  /// Throws a [StateError] if no service is registered for this type.
  T get<T>() {
    final Object? service = _services[T];
    if (service == null) {
      throw StateError('Service of type $T is not registered');
    }
    return service as T;
  }

  /// Whether a service of type [T] is registered.
  bool contains<T>() => _services.containsKey(T);

  /// Unregisters and returns the service of type [T] if it exists.
  T? unregister<T>() => _services.remove(T) as T?;
}
