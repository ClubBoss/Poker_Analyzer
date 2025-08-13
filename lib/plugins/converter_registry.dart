// Registry for converter plug-ins.

import 'package:poker_analyzer/models/saved_hand.dart';

import 'converter_plugin.dart';
import 'converter_info.dart';

/// Manages [ConverterPlugin] instances used for converting external data.
class ConverterRegistry {
  final List<ConverterPlugin> _plugins = <ConverterPlugin>[];

  /// Registers [plugin] if its [formatId] is not already used.
  void register(ConverterPlugin plugin) {
    if (findByFormatId(plugin.formatId) != null) {
      throw StateError(
          'Converter with id \'${plugin.formatId}\' is already registered');
    }
    _plugins.add(plugin);
  }

  /// Finds a converter plug-in by [id]. Returns `null` if not found.
  ConverterPlugin? findByFormatId(String id) {
    for (final ConverterPlugin plugin in _plugins) {
      if (plugin.formatId == id) {
        return plugin;
      }
    }
    return null;
  }

  /// Attempts to convert [data] using the converter associated with [id].
  /// Returns a [SavedHand] on success or `null` if no converter exists or the
  /// data could not be parsed.
  SavedHand? tryConvert(String id, String data) {
    final ConverterPlugin? plugin = findByFormatId(id);
    if (plugin == null) {
      return null;
    }
    return plugin.convertFrom(data);
  }

  /// Attempts to export [hand] using the converter associated with [id].
  /// Returns the external format string on success or `null` if no converter
  /// exists or the converter does not support exporting.
  String? tryExport(String id, SavedHand hand) {
    final ConverterPlugin? plugin = findByFormatId(id);
    if (plugin == null) {
      return null;
    }
    return plugin.convertTo(hand);
  }

  /// Validates [hand] before exporting with the converter associated with [id].
  ///
  /// Returns an error message if the converter rejects the hand, or `null` if
  /// the hand is valid for export or the converter is not found.
  String? validateForExport(String id, SavedHand hand) {
    final ConverterPlugin? plugin = findByFormatId(id);
    if (plugin == null) {
      return null;
    }
    return plugin.validate(hand);
  }

  /// Returns the list of registered converter format identifiers.
  List<String> dumpFormatIds() =>
      List<String>.unmodifiable(<String>[for (final p in _plugins) p.formatId]);

  /// Returns metadata about all registered converters.
  List<ConverterInfo> dumpConverters() =>
      List<ConverterInfo>.unmodifiable(<ConverterInfo>[
        for (final p in _plugins)
          ConverterInfo(
            formatId: p.formatId,
            description: p.description,
            capabilities: p.capabilities,
          )
      ]);

  /// Returns converter metadata filtered by capability flags.
  ///
  /// When a flag is `null` it will not be used for filtering.
  List<ConverterInfo> queryConverters({
    bool? supportsImport,
    bool? supportsExport,
    bool? requiresBoard,
  }) {
    return List<ConverterInfo>.unmodifiable(<ConverterInfo>[
      for (final p in _plugins)
        if ((supportsImport == null ||
                p.capabilities.supportsImport == supportsImport) &&
            (supportsExport == null ||
                p.capabilities.supportsExport == supportsExport) &&
            (requiresBoard == null ||
                p.capabilities.requiresBoard == requiresBoard))
          ConverterInfo(
            formatId: p.formatId,
            description: p.description,
            capabilities: p.capabilities,
          )
    ]);
  }

  /// Returns the first converter that successfully parses [data].
  ConverterPlugin? detectCompatible(String data) {
    final parts = data.split(RegExp(r'\n\s*\n'));
    for (final plugin in _plugins) {
      for (final part in parts) {
        if (plugin.convertFrom(part.trim()) != null) {
          return plugin;
        }
      }
    }
    return null;
  }
}
