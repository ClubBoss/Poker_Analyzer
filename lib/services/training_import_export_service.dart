import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';

class TrainingImportExportService {
  const TrainingImportExportService();

  /// Serialize spot map to json string.
  String serializeSpot(Map<String, dynamic> spot) => jsonEncode(spot);

  /// Deserialize spot from json string. Returns null if format is invalid.
  Map<String, dynamic>? deserializeSpot(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> importFromClipboard(BuildContext context) async {
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
      BuildContext context, Map<String, dynamic> spot) async {
    final jsonStr = serializeSpot(spot);
    await Clipboard.setData(ClipboardData(text: jsonStr));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Спот скопирован в буфер')));
    }
  }

  Future<Map<String, dynamic>?> importFromFile(BuildContext context) async {
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

  Future<void> exportToFile(BuildContext context, Map<String, dynamic> spot,
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
      BuildContext context, List<Map<String, dynamic>> spots) async {
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

