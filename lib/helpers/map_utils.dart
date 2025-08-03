import 'package:collection/collection.dart';

extension MapEqualsExtension<K, V> on Map<K, V> {
  static const _equality = DeepCollectionEquality();

  bool equals(Map<K, V> other) => _equality.equals(this, other);
}
