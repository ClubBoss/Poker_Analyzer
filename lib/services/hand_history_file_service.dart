import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../import_export/converter_pipeline.dart';
import '../plugins/plugin_loader.dart';
import '../plugins/plugin_manager.dart';
import '../plugins/converter_registry.dart';
import '../services/service_registry.dart';
import 'saved_hand_manager_service.dart';

/// Handles importing external hand history files using available converters.
class HandHistoryFileService {
  HandHistoryFileService._(this._handManager, this._pipeline);

  static Future<HandHistoryFileService> create(
      SavedHandManagerService manager) async {
    final loader = PluginLoader();
    final pluginManager = PluginManager();
    final registry = ServiceRegistry();
    await loader.loadAll(registry, pluginManager);
    final converterRegistry = registry.get<ConverterRegistry>();
    final pipeline = ConverterPipeline(converterRegistry);
    return HandHistoryFileService._(manager, pipeline);
  }

  final SavedHandManagerService _handManager;
  late final ConverterPipeline _pipeline;

  /// Prompts the user to select hand history files and imports them.
  Future<int> importFromFiles(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return 0;

    final converters = _pipeline.availableConverters(supportsImport: true);
    int imported = 0;

    for (final file in result.files) {
      final path = file.path;
      if (path == null) continue;
      try {
        final content = await File(path).readAsString();
        for (final info in converters) {
          final hand = _pipeline.tryImport(info.formatId, content);
          if (hand != null) {
            await _handManager.add(hand);
            imported++;
            break;
          }
        }
      } catch (_) {
        // Ignore read/parse errors.
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        imported > 0
            ? SnackBar(content: Text('Импортировано рук: $imported'))
            : const SnackBar(content: Text('Не удалось импортировать файлы')),
      );
    }
    return imported;
  }
}
