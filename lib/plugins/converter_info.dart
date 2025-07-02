/// Metadata for a registered converter.
import 'converter_format_capabilities.dart';

class ConverterInfo {
  ConverterInfo({
    required this.formatId,
    required this.description,
    required this.capabilities,
  });

  /// Identifier of the converter's format.
  final String formatId;

  /// Human readable description of the converter's format.
  final String description;

  /// Capabilities supported by this converter's format.
  final ConverterFormatCapabilities capabilities;
}
