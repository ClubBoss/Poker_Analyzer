/// Metadata for a registered converter.
class ConverterInfo {
  ConverterInfo({required this.formatId, required this.description});

  /// Identifier of the converter's format.
  final String formatId;

  /// Human readable description of the converter's format.
  final String description;
}
