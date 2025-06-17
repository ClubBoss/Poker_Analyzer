import 'package:poker_ai_analyzer/models/saved_hand.dart';
import '../plugins/converter_registry.dart';
import '../plugins/converter_info.dart';

/// High level pipeline for converting external hand formats.
///
/// This class is decoupled from the application core and relies only on the
/// [ConverterRegistry] provided through the plugin discovery system.
class ConverterPipeline {
  ConverterPipeline(this._registry);

  final ConverterRegistry _registry;

  /// Attempts to import [data] using the converter identified by [formatId].
  ///
  /// Returns a [SavedHand] on success or `null` if the format is unsupported
  /// or the converter failed to parse the data.
  SavedHand? tryImport(String formatId, String data) {
    return _registry.tryConvert(formatId, data);
  }

  /// Attempts to export [hand] using the converter identified by [formatId].
  ///
  /// Returns a string on success or `null` if the format is unsupported or the
  /// converter failed to produce a representation.
  String? tryExport(String formatId, SavedHand hand) {
    return _registry.tryExport(formatId, hand);
  }

  /// Validates [hand] for export using the converter identified by [formatId].
  ///
  /// Returns an error message if the converter rejects the hand, or `null` if
  /// the hand is valid for export or the converter is not found.
  String? validateForExport(String formatId, SavedHand hand) {
    return _registry.validateForExport(formatId, hand);
  }

  /// Lists all format identifiers for which converters are registered.
  List<String> supportedFormats() {
    return _registry.dumpFormatIds();
  }

  /// Lists metadata for all registered converters.
  List<ConverterInfo> availableConverters() {
    return _registry.dumpConverters();
  }
}
