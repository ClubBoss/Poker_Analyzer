import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:poker_ai_analyzer/import_export/converter_pipeline.dart';
import 'package:poker_ai_analyzer/plugins/plugin_loader.dart';
import 'package:poker_ai_analyzer/plugins/plugin_manager.dart';
import 'package:poker_ai_analyzer/plugins/converter_registry.dart';
import 'package:poker_ai_analyzer/services/service_registry.dart';
import 'saved_hand_manager_service.dart';
import '../models/saved_hand.dart';

/// Imports hand history files using available converters.
class HandHistoryFileImportService {
  HandHistoryFileImportService() {
    final registry = ServiceRegistry();
    final manager = PluginManager();
    final loader = PluginLoader();
    for (final plugin in loader.loadBuiltInPlugins()) {
      manager.load(plugin);
    }
    manager.initializeAll(registry);
    _pipeline = ConverterPipeline(registry.get<ConverterRegistry>());
  }

  late final ConverterPipeline _pipeline;

  /// Opens a file picker, converts selected files and adds them to [handManager].
  Future<int> importHandsFromFiles(
      BuildContext context, SavedHandManagerService handManager) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'json'],
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return 0;
    int count = 0;
    for (final f in result.files) {
      final path = f.path;
      if (path == null) continue;
      try {
        final content = await File(path).readAsString();
        SavedHand? hand;
        for (final id in _pipeline.supportedFormats()) {
          hand = _pipeline.tryImport(id, content);
          if (hand != null) break;
        }
        if (hand != null) {
          await handManager.add(hand);
          count++;
        }
      } catch (_) {}
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Импортировано раздач: $count')),
      );
    }
    return count;
  }
}
