/// Describes feature support for a converter format.
class ConverterFormatCapabilities {
  const ConverterFormatCapabilities({
    required this.supportsImport,
    required this.supportsExport,
    required this.requiresBoard,
    required this.supportsMultiStreet,
  });

  /// Whether the format can be imported.
  final bool supportsImport;

  /// Whether the format can export hands.
  final bool supportsExport;

  /// Whether the format requires a board to be present.
  final bool requiresBoard;

  /// Whether the format supports multiple board streets.
  final bool supportsMultiStreet;
}
