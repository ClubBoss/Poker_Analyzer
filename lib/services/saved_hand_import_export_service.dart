import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import '../models/saved_hand.dart';
import 'saved_hand_manager_service.dart';

class SavedHandImportExportService {
  SavedHandImportExportService(this.manager);

  final SavedHandManagerService manager;

  String serializeHand(SavedHand hand) => jsonEncode(hand.toJson());

  SavedHand deserializeHand(String jsonStr) =>
      SavedHand.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);

  Future<void> exportLastHand(BuildContext context) async {
    final hand = manager.lastHand;
    if (hand == null) return;
    await Clipboard.setData(ClipboardData(text: serializeHand(hand)));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Раздача скопирована.')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Неверный формат данных.')),
        );
      }
      return null;
    }
    try {
      return deserializeHand(data.text!);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Неверный формат данных.')),
        );
      }
      return null;
    }
  }

  Future<int> importAllHandsFromClipboard(BuildContext context) async {
    final data = await Clipboard.getData('text/plain');
    if (data == null || data.text == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid data format')),
        );
      }
      return 0;
    }
    try {
      final parsed = jsonDecode(data.text!);
      if (parsed is! List) throw const FormatException();

      int count = 0;
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid data format')),
        );
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Файл сохранён: $fileName')));
      OpenFile.open(file.path);
    }
  }

  Future<void> exportCsvFile(BuildContext context, SavedHand hand) async {
    final fileName = '${hand.name}_${hand.date.millisecondsSinceEpoch}.csv';
    final file = await _defaultFile(fileName);
    final buffer = StringBuffer()
      ..writeln('name,heroPosition,date,isFavorite,tags,comment')
      ..writeln(
          '${hand.name},${hand.heroPosition},${hand.date.toIso8601String()},${hand.isFavorite},"${hand.tags.join('|')}","${hand.comment ?? ''}"');
    await file.writeAsString(buffer.toString());
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Файл сохранён: $fileName')));
      OpenFile.open(file.path);
    }
  }

  Future<void> exportArchive(BuildContext context) async {
    final hands = manager.hands;
    if (hands.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No saved hands to export')));
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
    if (bytes == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Failed to create archive')));
      }
      return;
    }
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Archive saved: $name')));
    }
  }
}
