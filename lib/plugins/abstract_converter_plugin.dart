import 'package:poker_ai_analyzer/models/saved_hand.dart';

import 'converter_format_capabilities.dart';

/// Base interface for converter plug-ins providing shared behavior.
abstract class AbstractConverterPlugin {
  /// Creates the plugin with the provided [capabilities].
  const AbstractConverterPlugin(this.capabilities);

  /// Capabilities supported by this converter's format.
  final ConverterFormatCapabilities capabilities;

  /// Converts [hand] to an external representation.
  ///
  /// Implementations may return `null` if export is unsupported or fails.
  String? convertTo(SavedHand hand) => null;

  /// Validates whether [hand] can be exported by this converter.
  ///
  /// Returns an error message if the hand is incompatible with the format,
  /// or `null` if the hand is valid for export.
  String? validate(SavedHand hand) => null;
}
