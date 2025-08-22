import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../models/action_entry.dart';
import '../models/saved_hand.dart';
import '../models/action_evaluation_request.dart';
import '../models/card_model.dart';
import '../models/player_model.dart';
import 'saved_hand_manager_service.dart';
import '../import_export/converter_pipeline.dart';
import 'service_registry.dart';
import 'player_manager_service.dart';
import 'stack_manager_service.dart';
import 'board_manager_service.dart';
import 'action_sync_service.dart';
import 'pot_sync_service.dart';
import 'action_history_service.dart';
import 'board_reveal_service.dart';
import 'evaluation_queue_service.dart';
import 'current_hand_context_service.dart';
import 'playback_manager_service.dart';
import 'folded_players_service.dart';
import 'all_in_players_service.dart';
import 'action_tag_service.dart';

class SavedHandImportExportService {
  SavedHandImportExportService(this.manager, {ServiceRegistry? registry})
    : _pipeline = registry?.contains<ConverterPipeline>() == true
          ? registry!.get<ConverterPipeline>()
          : null;

  final SavedHandManagerService manager;
  final ConverterPipeline? _pipeline;

  /// Serialize [hand] to a JSON string.
  static String encode(SavedHand hand) => jsonEncode(hand.toJson());

  /// Deserialize a [SavedHand] from the given JSON string.
  static SavedHand decode(String jsonStr) =>
      SavedHand.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);

  /// Instance convenience wrapper around [encode].
  String serializeHand(SavedHand hand) => encode(hand);

  /// Instance convenience wrapper around [decode] with basic heuristics.
  SavedHand deserializeHand(String jsonStr) {
    final hand = decode(jsonStr);
    String? gameType = hand.gameType;
    String? category = hand.category;
    if (gameType == null || gameType.isEmpty) {
      gameType =
          (hand.buyIn != null ||
              hand.tournamentId?.isNotEmpty == true ||
              (hand.numberOfEntrants ?? 0) > 0)
          ? 'Tournament'
          : 'Cash Game';
    }
    if (category == null || category.isEmpty) {
      if (hand.boardStreet == 0) {
        int stack = 0;
        for (final s in hand.stackSizes.values) {
          stack = max(stack, s);
        }
        category = stack <= 20 ? 'Push/Fold' : 'Preflop';
      } else {
        category = 'Postflop';
      }
    }
    return (gameType != hand.gameType || category != hand.category)
        ? hand.copyWith(gameType: gameType, category: category)
        : hand;
  }

  SavedHand? _tryInternal(String text) {
    try {
      return deserializeHand(text);
    } catch (_) {
      return null;
    }
  }

  SavedHand buildHand({
    String? name,
    required PlayerManagerService playerManager,
    required StackManagerService stackService,
    required BoardManagerService boardManager,
    required ActionSyncService actionSync,
    required PotSyncService potSync,
    required ActionHistoryService actionHistory,
    required FoldedPlayersService foldedPlayers,
    required AllInPlayersService allInPlayers,
    required ActionTagService actionTags,
    required EvaluationQueueService queueService,
    required PlaybackManagerService playbackManager,
    required BoardRevealService boardReveal,
    required CurrentHandContextService handContext,
    String? tournamentId,
    int? buyIn,
    int? totalPrizePool,
    int? numberOfEntrants,
    String? gameType,
    String? category,
    int? activePlayerIndex,
  }) {
    final actions = actionSync.analyzerActions;
    potSync.updateEffectiveStacks(actions, playerManager.numberOfPlayers);
    final collapsed = actionHistory.collapsedStreets();
    final reveal = boardReveal.toJson();
    final hand = SavedHand(
      name: name ?? handContext.currentHandName ?? '',
      heroIndex: playerManager.heroIndex,
      heroPosition: playerManager.heroPosition,
      numberOfPlayers: playerManager.numberOfPlayers,
      playerCards: [
        for (int i = 0; i < playerManager.numberOfPlayers; i++)
          List<CardModel>.from(playerManager.playerCards[i]),
      ],
      boardCards: List<CardModel>.from(boardManager.boardCards),
      boardStreet: boardManager.boardStreet,
      revealedCards: [
        for (int i = 0; i < playerManager.numberOfPlayers; i++)
          [
            for (final c in playerManager.players[i].revealedCards)
              if (c != null) c,
          ],
      ],
      opponentIndex: playerManager.opponentIndex,
      activePlayerIndex: activePlayerIndex,
      actions: List<ActionEntry>.from(actions),
      stackSizes: Map<int, int>.from(stackService.initialStacks),
      currentBets: {
        for (int i = 0; i < playerManager.numberOfPlayers; i++)
          i: playerManager.players[i].bet,
      },
      remainingStacks: {
        for (int i = 0; i < playerManager.numberOfPlayers; i++)
          i: stackService.getStackForPlayer(i),
      },
      tournamentId: tournamentId,
      buyIn: buyIn,
      totalPrizePool: totalPrizePool,
      numberOfEntrants: numberOfEntrants,
      gameType: gameType,
      category: category,
      playerPositions: Map<int, String>.from(playerManager.playerPositions),
      playerTypes: Map<int, PlayerType>.from(playerManager.playerTypes),
      isFavorite: false,
      rating: 0,
      savedAt: DateTime.now(),
      date: DateTime.now(),
      effectiveStacksPerStreet: potSync.toNullableJson(),
      collapsedHistoryStreets: collapsed.isEmpty ? null : collapsed,
      foldedPlayers: foldedPlayers.toNullableList(),
      allInPlayers: allInPlayers.toNullableList(),
      actionTags: actionTags.toNullableMap(),
      pendingEvaluations: queueService.pending.isEmpty
          ? null
          : List<ActionEvaluationRequest>.from(queueService.pending),
      showFullBoard: reveal['showFullBoard'] as bool,
      revealStreet: reveal['revealStreet'] as int,
    );
    final withPlayback = playbackManager.applyTo(hand);
    return handContext.applyTo(withPlayback);
  }

  Future<void> exportLastHand(BuildContext context) async {
    final hand = manager.lastHand;
    if (hand == null) return;
    await Clipboard.setData(ClipboardData(text: serializeHand(hand)));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Раздача скопирована.')));
    }
  }

  Future<void> exportAllHands(BuildContext context) async {
    final hands = manager.hands;
    if (hands.isEmpty) return;
    final jsonStr = jsonEncode([for (final h in hands) h.toJson()]);
    await Clipboard.setData(ClipboardData(text: jsonStr));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${hands.length} hands exported to clipboard')),
      );
    }
  }

  Future<SavedHand?> importHandFromClipboard(BuildContext context) async {
    final data = await Clipboard.getData('text/plain');
    if (data == null || data.text == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Неверный формат данных.')));
      }
      return null;
    }
    SavedHand? hand;
    if (_pipeline != null) {
      for (final id in _pipeline!.supportedFormats()) {
        hand = _pipeline!.tryImport(id, data.text!);
        break;
      }
    }
    hand ??= _tryInternal(data.text!);
    if (hand == null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Неверный формат данных.')));
    }
    return hand;
  }

  Future<int> importAllHandsFromClipboard(BuildContext context) async {
    final data = await Clipboard.getData('text/plain');
    if (data == null || data.text == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid data format')));
      }
      return 0;
    }
    int count = 0;
    if (_pipeline != null) {
      final parts = data.text!.split(RegExp(r'\n\s*\n'));
      for (final part in parts) {
        for (final id in _pipeline!.supportedFormats()) {
          final hand = _pipeline!.tryImport(id, part.trim());
          if (hand != null) {
            try {
              await manager.add(hand);
              count++;
            } catch (_) {}
            break;
          }
        }
      }
      if (count > 0) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Imported $count hands')));
        }
        return count;
      }
    }
    try {
      final parsed = jsonDecode(data.text!);
      if (parsed is! List) throw const FormatException();

      for (final item in parsed) {
        if (item is Map<String, dynamic>) {
          try {
            await manager.add(SavedHand.fromJson(item));
            count++;
          } catch (_) {}
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          count > 0
              ? SnackBar(content: Text('Imported $count hands'))
              : const SnackBar(content: Text('Invalid data format')),
        );
      }
      return count;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid data format')));
      }
      return 0;
    }
  }

  Future<File> _defaultFile(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$name');
  }

  Future<void> exportJsonFile(BuildContext context, SavedHand hand) async {
    final fileName = '${hand.name}_${hand.date.millisecondsSinceEpoch}.json';
    final file = await _defaultFile(fileName);
    await file.writeAsString(jsonEncode(hand.toJson()));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Файл сохранён: $fileName')));
      OpenFilex.open(file.path);
    }
  }

  Future<void> exportCsvFile(BuildContext context, SavedHand hand) async {
    final fileName = '${hand.name}_${hand.date.millisecondsSinceEpoch}.csv';
    final file = await _defaultFile(fileName);
    final buffer = StringBuffer()
      ..writeln(
        'name,heroPosition,date,isFavorite,tags,comment,tournamentId,buyIn,totalPrizePool,numberOfEntrants,gameType',
      )
      ..writeln(
        '${hand.name},${hand.heroPosition},${hand.date.toIso8601String()},${hand.isFavorite},"${hand.tags.join('|')}","${hand.comment ?? ''}","${hand.tournamentId ?? ''}",${hand.buyIn ?? ''},${hand.totalPrizePool ?? ''},${hand.numberOfEntrants ?? ''},"${hand.gameType ?? ''}"',
      );
    await file.writeAsString(buffer.toString());
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Файл сохранён: $fileName')));
      OpenFilex.open(file.path);
    }
  }

  Future<void> exportArchive(BuildContext context) async {
    final hands = manager.hands;
    if (hands.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No saved hands to export')));
      }
      return;
    }
    final archive = Archive();
    for (final hand in hands) {
      final data = utf8.encode(serializeHand(hand));
      final name = '${hand.name}_${hand.date.millisecondsSinceEpoch}.json';
      archive.addFile(ArchiveFile(name, data.length, data));
    }
    final bytes = ZipEncoder().encode(archive);
    final fileName = 'saved_hands_${DateTime.now().millisecondsSinceEpoch}.zip';
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Hands Archive',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (savePath == null) return;
    final file = File(savePath);
    await file.writeAsBytes(bytes, flush: true);
    if (context.mounted) {
      final name = savePath.split(Platform.pathSeparator).last;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Archive saved: $name')));
    }
  }
}
