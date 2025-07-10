import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:poker_analyzer/plugins/plugin_loader.dart';
import 'package:poker_analyzer/plugins/plugin_manager.dart';
import 'package:poker_analyzer/plugins/converter_registry.dart';
import 'package:poker_analyzer/services/service_registry.dart';
import 'package:poker_analyzer/models/saved_hand.dart';

import 'saved_hand_manager_service.dart';

/// Handles importing external hand history files using available converters.
class HandHistoryFileService {
  HandHistoryFileService._(this._handManager, this._converters);

  static Future<HandHistoryFileService> create(
      SavedHandManagerService manager) async {
    final registry = ServiceRegistry();
    final loader = PluginLoader();
    final managerPlugin = PluginManager();
    await loader.loadAll(registry, managerPlugin);
    final converters = registry.get<ConverterRegistry>();
    return HandHistoryFileService._(manager, converters);
  }

  final SavedHandManagerService _handManager;
  final ConverterRegistry _converters;

  /// Prompts the user to select hand history files and imports them.
  Future<int> importFromFiles(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return 0;
    final imported = <SavedHand>[];
    final formats = _converters.dumpFormatIds();
    for (final f in result.files) {
      final path = f.path;
      if (path == null) continue;
      try {
        final data = await File(path).readAsString();
        for (final id in formats) {
          final hand = _converters.tryConvert(id, data);
          if (hand != null) {
            imported.add(hand);
            break;
          }
        }
      } catch (_) {}
    }
    if (imported.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось импортировать файлы')),
        );
      }
      return 0;
    }
    await _handManager.addHands(imported);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Импортировано ${imported.length} раздач')),
      );
    }
    return imported.length;
  }
}
