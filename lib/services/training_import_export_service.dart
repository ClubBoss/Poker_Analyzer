import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

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
  TrainingImportExportService();

  /// Create a TrainingSpot from a saved hand, including tournament metadata.
  TrainingSpot fromSavedHand(SavedHand hand) =>
      TrainingSpot.fromSavedHand(hand);

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
          List<CardModel>.from(playerManager.playerCards[i]),
      ],
      boardCards: List<CardModel>.from(boardManager.boardCards),
      actions: List<ActionEntry>.from(actionSync.analyzerActions),
      heroIndex: playerManager.heroIndex,
      numberOfPlayers: playerManager.numberOfPlayers,
      playerTypes: [
        for (int i = 0; i < playerManager.numberOfPlayers; i++)
          playerManager.playerTypes[i] ?? PlayerType.unknown,
      ],
      positions: [
        for (int i = 0; i < playerManager.numberOfPlayers; i++)
          playerManager.playerPositions[i],
      ],
      stacks: [
        for (int i = 0; i < playerManager.numberOfPlayers; i++)
          stackManager.getStackForPlayer(i),
      ],
      equities: null,
      tournamentId: tournamentId,
      buyIn: buyIn,
      totalPrizePool: totalPrizePool,
      numberOfEntrants: numberOfEntrants,
      gameType: gameType,
      category: null,
      tags: const [],
      difficulty: 3,
      createdAt: DateTime.now(),
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

  /// Export a TrainingSpot to a formatted JSON string including tournament metadata.
  String exportJsonSpot(TrainingSpot spot) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(spot.toJson());
  }

  /// Export tournament metadata from a TrainingSpot to CSV.
  /// Null values are omitted from both header and row.
  String exportCsvSpot(TrainingSpot spot) {
    final headers = <String>[];
    final values = <String>[];

    void addField(String name, Object? value) {
      if (value == null) return;
      headers.add(name);
      final str = value.toString();
      if (str.contains(',') || str.contains('"') || str.contains('\n')) {
        final escaped = str.replaceAll('"', '""');
        values.add('"$escaped"');
      } else {
        values.add(str);
      }
    }

    addField('tournamentId', spot.tournamentId);
    addField('buyIn', spot.buyIn);
    addField('totalPrizePool', spot.totalPrizePool);
    addField('numberOfEntrants', spot.numberOfEntrants);
    addField('gameType', spot.gameType);

    return '${headers.join(',')}\n${values.join(',')}';
  }

  /// Export multiple [TrainingSpot]s to CSV. Only include headers once.
  /// Fields that are `null` for a spot will produce empty cells in its row.
  String exportAllSpotsCsv(List<TrainingSpot> spots) {
    if (spots.isEmpty) return '';

    const fieldOrder = [
      'tournamentId',
      'buyIn',
      'totalPrizePool',
      'numberOfEntrants',
      'gameType',
    ];

    final headers = <String>[];
    bool added(String name) => headers.contains(name);
    void tryAdd(String name, bool include) {
      if (include && !added(name)) headers.add(name);
    }

    for (final s in spots) {
      tryAdd('tournamentId', s.tournamentId != null);
      tryAdd('buyIn', s.buyIn != null);
      tryAdd('totalPrizePool', s.totalPrizePool != null);
      tryAdd('numberOfEntrants', s.numberOfEntrants != null);
      tryAdd('gameType', s.gameType != null);
    }

    // Preserve predefined order
    headers.sort(
      (a, b) => fieldOrder.indexOf(a).compareTo(fieldOrder.indexOf(b)),
    );

    String escapeValue(Object value) {
      final str = value.toString();
      if (str.contains(',') || str.contains('"') || str.contains('\n')) {
        final escaped = str.replaceAll('"', '""');
        return '"$escaped"';
      }
      return str;
    }

    final buffer = StringBuffer();
    buffer.writeln(headers.join(','));

    for (final s in spots) {
      final row = <String>[];
      for (final h in headers) {
        Object? val;
        switch (h) {
          case 'tournamentId':
            val = s.tournamentId;
            break;
          case 'buyIn':
            val = s.buyIn;
            break;
          case 'totalPrizePool':
            val = s.totalPrizePool;
            break;
          case 'numberOfEntrants':
            val = s.numberOfEntrants;
            break;
          case 'gameType':
            val = s.gameType;
            break;
        }
        row.add(val == null ? '' : escapeValue(val));
      }
      buffer.writeln(row.join(','));
    }

    return buffer.toString().trimRight();
  }

  /// Export multiple [TrainingSpot]s to Markdown summarizing tournament metadata.
  /// Each spot gets a numbered heading followed by a bullet list of non-null fields.
  String exportAllSpotsMarkdown(List<TrainingSpot> spots) {
    if (spots.isEmpty) return '';

    const fieldOrder = [
      'tournamentId',
      'buyIn',
      'totalPrizePool',
      'numberOfEntrants',
      'gameType',
    ];

    String? getField(TrainingSpot s, String field) {
      switch (field) {
        case 'tournamentId':
          return s.tournamentId;
        case 'buyIn':
          return s.buyIn?.toString();
        case 'totalPrizePool':
          return s.totalPrizePool?.toString();
        case 'numberOfEntrants':
          return s.numberOfEntrants?.toString();
        case 'gameType':
          return s.gameType;
      }
      return null;
    }

    final buffer = StringBuffer();
    for (int i = 0; i < spots.length; i++) {
      final s = spots[i];
      buffer.writeln('### Spot ${i + 1}');
      for (final field in fieldOrder) {
        final val = getField(s, field);
        if (val != null) {
          buffer.writeln('- **$field:** $val');
        }
      }
      buffer.writeln();
    }

    return buffer.toString().trimRight();
  }

  /// Parse multiple tournament metadata rows from a CSV string.
  /// Returns an empty list if no valid rows are found.
  List<TrainingSpot> importAllSpotsCsv(String csvStr) {
    final spots = <TrainingSpot>[];
    final lines = csvStr.trim().split(RegExp(r'\r?\n'));
    if (lines.length < 2) return spots;

    final headers = _parseCsvLine(lines.first).map((h) => h.trim()).toList();

    String? strOrNull(String? v) {
      if (v == null) return null;
      final t = v.trim();
      return t.isEmpty ? null : t;
    }

    int? intOrNull(String? v) => int.tryParse(v?.trim() ?? '');

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final values = _parseCsvLine(line);
        if (values.every((v) => v.trim().isEmpty)) continue;

        final map = <String, String>{};
        for (int j = 0; j < headers.length && j < values.length; j++) {
          map[headers[j]] = values[j].trim();
        }

        spots.add(
          TrainingSpot(
            playerCards: const [],
            boardCards: const [],
            actions: const [],
            heroIndex: 0,
            numberOfPlayers: 0,
            playerTypes: const [],
            positions: const [],
            stacks: const [],
            equities: null,
            tournamentId: strOrNull(map['tournamentId']),
            buyIn: intOrNull(map['buyIn']),
            totalPrizePool: intOrNull(map['totalPrizePool']),
            numberOfEntrants: intOrNull(map['numberOfEntrants']),
            gameType: strOrNull(map['gameType']),
            difficulty: 3,
          ),
        );
      } catch (_) {
        // Skip malformed rows
      }
    }

    return spots;
  }

  /// Parse tournament metadata from a CSV string. Returns `null` on failure.
  TrainingSpot? importCsvSpot(String csvStr) {
    try {
      final lines = csvStr.trim().split(RegExp(r'\r?\n'));
      if (lines.length < 2) return null;

      final headers = _parseCsvLine(lines.first);
      final values = _parseCsvLine(lines[1]);

      final map = <String, String>{};
      for (int i = 0; i < headers.length && i < values.length; i++) {
        map[headers[i].trim()] = values[i].trim();
      }

      String? strOrNull(String? v) {
        if (v == null) return null;
        final t = v.trim();
        return t.isEmpty ? null : t;
      }

      int? intOrNull(String? v) => int.tryParse(v?.trim() ?? '');

      return TrainingSpot(
        playerCards: const [],
        boardCards: const [],
        actions: const [],
        heroIndex: 0,
        numberOfPlayers: 0,
        playerTypes: const [],
        positions: const [],
        stacks: const [],
        equities: null,
        tournamentId: strOrNull(map['tournamentId']),
        buyIn: intOrNull(map['buyIn']),
        totalPrizePool: intOrNull(map['totalPrizePool']),
        numberOfEntrants: intOrNull(map['numberOfEntrants']),
        gameType: strOrNull(map['gameType']),
        difficulty: 3,
      );
    } catch (_) {
      return null;
    }
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString());
    return result;
  }

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
            SnackBar(content: Text('Неверный формат данных')),
          );
        }
        return null;
      }
      final spot = deserializeSpot(data.text!);
      if (spot == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Неверный формат данных')),
          );
        }
        return null;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Спот загружен из буфера')),
        );
      }
      return spot;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ошибка загрузки')));
      }
      return null;
    }
  }

  Future<void> exportToClipboard(
    BuildContext context,
    TrainingSpot spot,
  ) async {
    final jsonStr = serializeSpot(spot);
    await Clipboard.setData(ClipboardData(text: jsonStr));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Спот скопирован в буфер')));
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
            SnackBar(content: Text('Неверный формат файла')),
          );
        }
        return null;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Файл загружен: ${file.path.split(Platform.pathSeparator).last}',
            ),
          ),
        );
      }
      return spot;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ошибка чтения файла')));
      }
      return null;
    }
  }

  Future<void> exportToFile(
    BuildContext context,
    TrainingSpot spot, {
    String? fileName,
  }) async {
    final name =
        fileName ??
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
              onPressed: () => OpenFilex.open(file.path),
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения файла')),
        );
      }
    }
  }

  Future<void> exportArchive(
    BuildContext context,
    List<TrainingSpot> spots,
  ) async {
    if (spots.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Нет спотов для экспорта')),
        );
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
    final fileName =
        'training_spots_${DateTime.now().millisecondsSinceEpoch}.zip';
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Архив сохранён: $displayName')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения архива')),
        );
      }
    }
  }
}
