import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/training_spot.dart';
import 'training_import_export_service.dart';

class TrainingSpotFileService {
  final TrainingImportExportService _importExport;

  const TrainingSpotFileService([this._importExport = const TrainingImportExportService()]);

  Future<List<TrainingSpot>> importSpotsCsv(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.isEmpty) return [];
    final path = result.files.single.path;
    if (path == null) return [];
    final file = File(path);
    try {
      final content = await file.readAsString();
      final spots = _importExport.importAllSpotsCsv(content);
      if (spots.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка импорта CSV')),
          );
        }
        return [];
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Импортировано спотов: ${spots.length}')),
        );
      }
      return spots;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ошибка чтения файла')));
      }
      return [];
    }
  }

  Future<String?> exportSpotsMarkdown(BuildContext context, List<TrainingSpot> spots) async {
    if (spots.isEmpty) return null;
    final markdown = _importExport.exportAllSpotsMarkdown(spots);
    if (markdown.isEmpty) return null;

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'spots_${DateTime.now().millisecondsSinceEpoch}.md';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(markdown);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Файл сохранён: ${file.path}')),
      );
    }
    return file.path;
  }
}
