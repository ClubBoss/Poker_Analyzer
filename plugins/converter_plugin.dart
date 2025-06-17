import 'package:poker_ai_analyzer/models/saved_hand.dart';

/// Plug-in contract for converting external formats into [SavedHand] models.
abstract class ConverterPlugin {
  /// Unique identifier of the supported external format.
  String get formatId;

  /// Human readable description of the supported format.
  String get description;

  /// Converts [externalData] to a [SavedHand].
  ///
  /// Returns `null` if [externalData] cannot be parsed.
  SavedHand? convertFrom(String externalData);

  /// Converts [hand] to an external representation.
  ///
  /// Implementations may return `null` if export is unsupported or fails.
  String? convertTo(SavedHand hand) => null;
}
