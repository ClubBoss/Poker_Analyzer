import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';

import '../models/action_entry.dart';
import '../models/player_model.dart';
import '../models/training_spot.dart';
import '../models/card_model.dart';
import '../models/saved_hand.dart';
import 'action_sync_service.dart';
import 'board_manager_service.dart';
import 'current_hand_context_service.dart';
import 'player_manager_service.dart';
import 'playback_manager_service.dart';
import 'stack_manager_service.dart';

class TrainingImportExportService {
  const TrainingImportExportService();

  /// Create a TrainingSpot from a saved hand, including tournament metadata.
  TrainingSpot fromSavedHand(SavedHand hand) => TrainingSpot.fromSavedHand(hand);

  /// Build a TrainingSpot from current services.
  TrainingSpot buildSpot({
    required PlayerManagerService playerManager,
    required BoardManagerService boardManager,
    required ActionSyncService actionSync,
    required StackManagerService stackManager,
    String? tournamentId,
    int? buyIn,
    int? totalPrizePool,
    int? numberOfEntrants,
    String? gameType,
  }) {
    return TrainingSpot(
      playerCards: [
        for (int i = 0; i < playerManager.numberOfPlayers; i++)
          List<CardModel>.from(playerManager.playerCards[i])
      ],
      boardCards: List<CardModel>.from(boardManager.boardCards),
      actions: List<ActionEntry>.from(actionSync.analyzerActions),
      heroIndex: playerManager.heroIndex,
      numberOfPlayers: playerManager.numberOfPlayers,
      playerTypes: [
        for (int i = 0; i < playerManager.numberOfPlayers; i++)
          playerManager.playerTypes[i] ?? PlayerType.unknown
      ],
      positions: [
        for (int i = 0; i < playerManager.numberOfPlayers; i++)
          playerManager.playerPositions[i]
      ],
      stacks: [
        for (int i = 0; i < playerManager.numberOfPlayers; i++)
          stackManager.getStackForPlayer(i)
      ],
      tournamentId: tournamentId,
      buyIn: buyIn,
      totalPrizePool: totalPrizePool,
      numberOfEntrants: numberOfEntrants,
      gameType: gameType,
    );
  }

  /// Apply a spot map to the provided services.
  void applySpot(
    TrainingSpot spot, {
    required PlayerManagerService playerManager,
    required BoardManagerService boardManager,
    required ActionSyncService actionSync,
    required PlaybackManagerService playbackManager,
    required CurrentHandContextService handContext,
  }) {
    actionSync.setAnalyzerActions(List<ActionEntry>.from(spot.actions));
    final map = spot.toJson();
    playerManager.loadFromMap(map);
    boardManager.loadFromMap(map);
    playbackManager.resetHand();
    handContext.clearName();
    handContext.tournamentId = spot.tournamentId;
    handContext.buyIn = spot.buyIn;
    handContext.totalPrizePool = spot.totalPrizePool;
    handContext.numberOfEntrants = spot.numberOfEntrants;
    handContext.gameType = spot.gameType;
  }

  /// Serialize a TrainingSpot to json string.
  String serializeSpot(TrainingSpot spot) => jsonEncode(spot.toJson());

  /// Deserialize spot from json string. Returns null if format is invalid.
  TrainingSpot? deserializeSpot(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return TrainingSpot.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
    return null;
  }

  Future<TrainingSpot?> importFromClipboard(BuildContext context) async {
    try {
      final data = await Clipboard.getData('text/plain');
      if (data == null || data.text == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Неверный формат данных')));
        }
        return null;
      }
      final spot = deserializeSpot(data.text!);
      if (spot == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Неверный формат данных')));
        }
        return null;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Спот загружен из буфера')));
      }
      return spot;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ошибка загрузки')));
      }
      return null;
    }
  }

  Future<void> exportToClipboard(
      BuildContext context, TrainingSpot spot) async {
    final jsonStr = serializeSpot(spot);
    await Clipboard.setData(ClipboardData(text: jsonStr));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Спот скопирован в буфер')));
    }
  }

  Future<TrainingSpot?> importFromFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return null;
    final path = result.files.single.path;
    if (path == null) return null;
    final file = File(path);
    try {
      final content = await file.readAsString();
      final spot = deserializeSpot(content);
      if (spot == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Неверный формат файла')));
        }
        return null;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Файл загружен: ${file.path.split(Platform.pathSeparator).last}')));
      }
      return spot;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ошибка чтения файла')));
      }
      return null;
    }
  }

  Future<void> exportToFile(BuildContext context, TrainingSpot spot,
      {String? fileName}) async {
    final name = fileName ??
        'training_spot_${DateTime.now().millisecondsSinceEpoch}.json';
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Сохранить спот',
      fileName: name,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (savePath == null) return;
    final file = File(savePath);
    try {
      await file.writeAsString(serializeSpot(spot));
      if (context.mounted) {
        final displayName = savePath.split(Platform.pathSeparator).last;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Файл сохранён: $displayName'),
            action: SnackBarAction(
              label: 'Открыть',
              onPressed: () => OpenFile.open(file.path),
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ошибка сохранения файла')));
      }
    }
  }

  Future<void> exportArchive(
      BuildContext context, List<TrainingSpot> spots) async {
    if (spots.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Нет спотов для экспорта')));
      }
      return;
    }
    final archive = Archive();
    for (int i = 0; i < spots.length; i++) {
      final data = utf8.encode(serializeSpot(spots[i]));
      final name = 'spot_${i + 1}.json';
      archive.addFile(ArchiveFile(name, data.length, data));
    }
    final bytes = ZipEncoder().encode(archive);
    if (bytes == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Не удалось создать архив')));
      }
      return;
    }
    final fileName = 'training_spots_${DateTime.now().millisecondsSinceEpoch}.zip';
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Сохранить архив',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (savePath == null) return;
    final file = File(savePath);
    try {
      await file.writeAsBytes(bytes, flush: true);
      if (context.mounted) {
        final displayName = savePath.split(Platform.pathSeparator).last;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Архив сохранён: $displayName')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ошибка сохранения архива')));
      }
    }
  }
}

