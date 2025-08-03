import 'v2/training_pack_spot.dart';

/// Defines a base spot and a list of variation rules that can be expanded
/// into multiple [TrainingPackSpot]s.
class TrainingPackTemplateSet {
  /// Shared logic and metadata for all generated spots.
  final TrainingPackSpot baseSpot;

  /// Each variation is a map of property name to a list of values that should
  /// be combined with other properties to produce the cartesian product of
  /// all options.
  final List<Map<String, List<dynamic>>> variations;

  const TrainingPackTemplateSet({
    required this.baseSpot,
    this.variations = const [],
  });
}
