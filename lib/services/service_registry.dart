/// Centralized registry for application services.
///
/// Services are registered and looked up by their runtime type. Attempts to
/// register the same type twice or retrieve an unregistered service will throw
/// a [StateError]. Child registries created via [createChild] inherit the
/// parent's services and fall back to the parent when a lookup fails locally.
class ServiceRegistry {
  ServiceRegistry({ServiceRegistry? parent}) : _parent = parent;

  final Map<Type, Object> _services = <Type, Object>{};
  final ServiceRegistry? _parent;

  /// Creates a child registry that inherits services from this registry.
  ServiceRegistry createChild() => ServiceRegistry(parent: this);

  /// Registers [service] for type [T].
  /// Throws a [StateError] if a service of this type is already registered.
  void register<T>(T service) {
    final Type type = T;
    if (_services.containsKey(type)) {
      throw StateError('Service of type $T is already registered');
    }
    _services[type] = service as Object;
  }

  /// Registers [service] for type [T] only if absent.
  ///
  /// This allows plugins to provide default implementations without
  /// overriding services that may have been registered earlier.
  void registerIfAbsent<T>(T service) {
    if (!contains<T>()) {
      register<T>(service);
    }
  }

  /// Returns the registered service for type [T].
  /// Throws a [StateError] if no service is registered for this type.
  T get<T>() {
    final Object? service = _services[T];
    if (service != null) {
      return service as T;
    }
    if (_parent != null) {
      return _parent.get<T>();
    }
    throw StateError('Service of type $T is not registered');
  }

  /// Whether a service of type [T] is registered.
  bool contains<T>() {
    if (_services.containsKey(T)) {
      return true;
    }
    return _parent?.contains<T>() ?? false;
  }

  /// Unregisters and returns the service of type [T] if it exists.
  T? unregister<T>() => _services.remove(T) as T?;

  /// Returns the list of types registered in this registry only.
  List<Type> dump() => List<Type>.unmodifiable(_services.keys);

  /// Returns all registered types visible from this registry,
  /// including those from parent registries.
  List<Type> dumpAll() {
    final Set<Type> types = <Type>{..._services.keys};
    if (_parent != null) {
      types.addAll(_parent.dumpAll());
    }
    return List<Type>.unmodifiable(types);
  }
}
