import 'package:poker_ai_analyzer/models/saved_hand.dart';

import 'abstract_converter_plugin.dart';
import 'converter_format_capabilities.dart';

/// Plug-in contract for converting external formats into [SavedHand] models.
abstract class ConverterPlugin extends AbstractConverterPlugin {
  ConverterPlugin({
    required this.formatId,
    required this.description,
    required ConverterFormatCapabilities capabilities,
  }) : super(capabilities);

  /// Unique identifier of the supported external format.
  final String formatId;

  /// Human readable description of the supported format.
  final String description;

  /// Converts [externalData] to a [SavedHand].
  ///
  /// Returns `null` if [externalData] cannot be parsed.
  SavedHand? convertFrom(String externalData);

  /// Converts [hand] to an external representation.
  ///
  /// Implementations may return `null` if export is unsupported or fails.
  @override
  String? convertTo(SavedHand hand) => super.convertTo(hand);

  /// Validates whether [hand] can be exported by this converter.
  ///
  /// Returns an error message if the hand is incompatible with the format,
  /// or `null` if the hand is valid for export.
  @override
  String? validate(SavedHand hand) => super.validate(hand);
}
