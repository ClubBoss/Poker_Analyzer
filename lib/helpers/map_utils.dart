import 'package:collection/collection.dart';

extension MapEqualsExtension on Map<String, dynamic> {
  bool equals(Map<String, dynamic> other) => const DeepCollectionEquality().equals(this, other);
}
