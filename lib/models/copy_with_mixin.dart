mixin CopyWithMixin<T> {
  /// Factory that reconstructs [T] from JSON.
  T Function(Map<String, dynamic> json) get fromJson;

  /// Serializes the object into JSON.
  Map<String, dynamic> toJson();

  /// Returns a copy of this object with the provided [changes] applied.
  ///
  /// Example:
  /// ```dart
  /// final updated = original.copyWith({'name': 'New'});
  /// ```
  T copyWith(Map<String, dynamic> changes) {
    final data = Map<String, dynamic>.from(toJson());
    data.addAll(changes);
    return fromJson(data);
  }
}
