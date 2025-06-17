import 'package:poker_ai_analyzer/models/saved_hand.dart';

/// Plug-in contract for converting external formats into [SavedHand] models.
abstract class ConverterPlugin {
  /// Unique identifier of the supported external format.
  String get formatId;

  /// Converts [externalData] to a [SavedHand].
  ///
  /// Returns `null` if [externalData] cannot be parsed.
  SavedHand? convertFrom(String externalData);
}
