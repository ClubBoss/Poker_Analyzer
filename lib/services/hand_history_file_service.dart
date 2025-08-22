import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:poker_analyzer/plugins/plugin_loader.dart';
import 'package:poker_analyzer/plugins/plugin_manager.dart';
import 'package:poker_analyzer/plugins/converter_registry.dart';
import 'package:poker_analyzer/services/service_registry.dart';
import 'package:poker_analyzer/models/saved_hand.dart';
import 'package:poker_analyzer/models/card_model.dart';
import '../helpers/hand_utils.dart';
import '../screens/import_session_summary_screen.dart';
import 'hand_analyzer_service.dart';
import 'hand_analysis_history_service.dart';
import 'xp_tracker_service.dart';

import 'saved_hand_manager_service.dart';

/// Handles importing external hand history files using available converters.
class HandHistoryFileService {
  HandHistoryFileService._(this._handManager, this._converters);

  static Future<HandHistoryFileService> create(
    SavedHandManagerService manager,
  ) async {
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
          SnackBar(content: Text('Не удалось импортировать файлы')),
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
    if (context.mounted) {
      final analyzer = Provider.of<HandAnalyzerService>(context, listen: false);
      final xp = Provider.of<XPTrackerService>(context, listen: false);
      final history = Provider.of<HandAnalysisHistoryService>(
        context,
        listen: false,
      );
      int correct = 0;
      final mistakes = <ImportMistake>[];
      for (final h in imported) {
        final hero = h.playerCards.length > h.heroIndex
            ? h.playerCards[h.heroIndex]
            : <CardModel>[];
        if (hero.length < 2) continue;
        final stack = h.stackSizes[h.heroIndex] ?? 0;
        final record = analyzer.analyzePush(
          cards: hero,
          stack: stack,
          playerCount: h.numberOfPlayers,
          heroIndex: h.heroIndex,
          level: xp.level,
          anteBb: h.anteBb,
        );
        if (record == null) continue;
        await history.add(record);
        final act = heroAction(h)?.action.toLowerCase() ?? '';
        if (act == record.action.toLowerCase()) {
          correct++;
        } else {
          mistakes.add(
            ImportMistake(
              cards: hero,
              actual: act,
              expected: record.action,
              ev: record.ev,
              icm: record.icm,
            ),
          );
        }
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ImportSessionSummaryScreen(
            total: imported.length,
            correct: correct,
            mistakes: mistakes,
          ),
        ),
      );
    }
    return imported.length;
  }
}
