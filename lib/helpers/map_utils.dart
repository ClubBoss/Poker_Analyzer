import 'package:collection/collection.dart';

extension MapEqualsExtension<K, V> on Map<K, V> {
  bool equals(Map<K, V> other) => const DeepCollectionEquality().equals(this, other);
}
