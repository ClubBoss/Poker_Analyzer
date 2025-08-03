mixin SingletonMixin<T extends Object> {
  static final Map<Type, Object> _instances = <Type, Object>{};

  /// Returns the singleton instance for type [T], creating it with [creator]
  /// if it hasn't been initialized yet.
  static T instance<T extends Object>(T Function() creator) {
    return _instances.putIfAbsent(T, () => creator()) as T;
  }
}
