import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

import 'player_profile_service.dart';
import '../models/player_model.dart';

class PlayerProfileImportExportService {
  PlayerProfileImportExportService(this.profile);

  final PlayerProfileService profile;

  /// Convert the current player profile to a serializable map.
  Map<String, dynamic> toMap() => {
        'heroIndex': profile.heroIndex,
        'heroPosition': profile.heroPosition,
        'numberOfPlayers': profile.numberOfPlayers,
        if (profile.opponentIndex != null)
          'opponentIndex': profile.opponentIndex,
        'playerPositions': [
          for (int i = 0; i < profile.numberOfPlayers; i++)
            profile.playerPositions[i],
        ],
        'playerTypes': [
          for (int i = 0; i < profile.numberOfPlayers; i++)
            profile.playerTypes[i]?.name ?? PlayerType.unknown.name,
        ],
        'playerNames': [for (final p in profile.players) p.name],
        'playerNotes': [
          for (int i = 0; i < profile.numberOfPlayers; i++)
            profile.playerNotes[i] ?? '',
        ],
      };

  /// Load player profile information from a previously serialized map.
  void loadFromMap(Map<String, dynamic> data) {
    final heroIndex = data['heroIndex'] as int? ?? 0;
    final heroPosition =
        data['heroPosition'] as String? ?? profile.heroPosition;
    final count = data['numberOfPlayers'] as int? ?? profile.numberOfPlayers;
    final opponent = data['opponentIndex'] as int?;
    final posList = (data['playerPositions'] as List?)?.cast<String>() ?? [];
    final typeList = (data['playerTypes'] as List?)?.cast<String>() ?? [];
    final names = (data['playerNames'] as List?)?.cast<String>() ?? [];
    final notes = (data['playerNotes'] as List?)?.cast<String>() ?? [];

    profile.onPlayerCountChanged(count);
    profile.setHeroIndex(heroIndex);
    profile.heroPosition = heroPosition;
    profile.opponentIndex =
        opponent != null && opponent < profile.numberOfPlayers
            ? opponent
            : null;

    profile.playerPositions.clear();
    for (int i = 0; i < posList.length && i < profile.numberOfPlayers; i++) {
      profile.playerPositions[i] = posList[i];
    }

    profile.playerTypes.clear();
    for (int i = 0; i < typeList.length && i < profile.numberOfPlayers; i++) {
      final type = PlayerType.values.firstWhere(
        (e) => e.name == typeList[i],
        orElse: () => PlayerType.unknown,
      );
      profile.playerTypes[i] = type;
    }

    profile.playerNotes.clear();
    for (int i = 0; i < notes.length && i < profile.numberOfPlayers; i++) {
      if (notes[i].trim().isNotEmpty) {
        profile.playerNotes[i] = notes[i].trim();
      }
    }

    for (int i = 0; i < names.length && i < profile.players.length; i++) {
      final p = profile.players[i];
      profile.players[i] = p.copyWith(name: names[i]);
    }

    profile.updatePositions();
  }

  String serialize() => jsonEncode(toMap());

  bool deserialize(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        loadFromMap(Map<String, dynamic>.from(decoded));
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> exportToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: serialize()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile copied to clipboard')),
      );
    }
  }

  Future<void> importFromClipboard(BuildContext context) async {
    try {
      final data = await Clipboard.getData('text/plain');
      if (data == null || data.text == null || !deserialize(data.text!)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid clipboard data')),
          );
        }
        return;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile loaded from clipboard')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to read clipboard')),
        );
      }
    }
  }

  Future<void> exportToFile(BuildContext context) async {
    final fileName =
        'player_profile_${DateTime.now().millisecondsSinceEpoch}.json';
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Profile',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (savePath == null) return;
    final file = File(savePath);
    try {
      await file.writeAsString(serialize());
      if (context.mounted) {
        final displayName = savePath.split(Platform.pathSeparator).last;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File saved: $displayName'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => OpenFilex.open(file.path),
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save file')));
      }
    }
  }

  Future<void> importFromFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    final file = File(path);
    try {
      final content = await file.readAsString();
      if (!deserialize(content)) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Invalid file format')));
        }
        return;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File loaded: ${file.path.split(Platform.pathSeparator).last}',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to read file')));
      }
    }
  }

  Future<void> exportArchive(BuildContext context) async {
    final archive = Archive();
    final data = utf8.encode(serialize());
    const name = 'profile.json';
    archive.addFile(ArchiveFile(name, data.length, data));
    final bytes = ZipEncoder().encode(archive);
    final fileName =
        'player_profile_${DateTime.now().millisecondsSinceEpoch}.zip';
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Profile Archive',
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
        ).showSnackBar(SnackBar(content: Text('Archive saved: $displayName')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save archive')));
      }
    }
  }
}
