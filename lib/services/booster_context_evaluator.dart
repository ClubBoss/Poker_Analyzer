import 'package:meta/meta.dart';

/// Evaluates whether a booster type is relevant to current weaknesses.
@immutable
class BoosterContextEvaluator {
  const BoosterContextEvaluator();

  /// Returns `true` if [type] is currently relevant.
  Future<bool> isRelevant(String type) async => true;
}
