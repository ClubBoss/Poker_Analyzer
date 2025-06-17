// Registry for converter plug-ins.

import 'package:poker_ai_analyzer/models/saved_hand.dart';

import 'converter_plugin.dart';

/// Manages [ConverterPlugin] instances used for converting external data.
class ConverterRegistry {
  final List<ConverterPlugin> _plugins = <ConverterPlugin>[];

  /// Registers [plugin] if its [formatId] is not already used.
  void register(ConverterPlugin plugin) {
    if (findByFormatId(plugin.formatId) != null) {
      throw StateError('Converter with id \'${plugin.formatId}\' is already registered');
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
}
