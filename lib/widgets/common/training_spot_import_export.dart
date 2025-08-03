import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/training_spot.dart';

class TrainingSpotImportExport {
  const TrainingSpotImportExport._();

  static Future<void> exportPack(List<TrainingSpot> spots) async {
    if (spots.isEmpty) return;
    const encoder = JsonEncoder.withIndent('  ');
    final jsonStr = encoder.convert([for (final s in spots) s.toJson()]);
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/training_spots_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonStr);
    await Share.shareXFiles([XFile(file.path)], text: 'training_spots.json');
  }

  static Future<void> exportNamedPack(
    BuildContext context,
    List<TrainingSpot> spots,
    String name,
  ) async {
    if (spots.isEmpty) return;
    const encoder = JsonEncoder.withIndent('  ');
    final jsonStr = encoder.convert([for (final s in spots) s.toJson()]);
    final dir = await getTemporaryDirectory();
    final safe = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final file = File('${dir.path}/$safe.json');
    await file.writeAsString(jsonStr);
    await Share.shareXFiles([XFile(file.path)], text: '$safe.json');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Пакет "$name" создан, спотов: ${spots.length}')),
    );
  }

  static Future<void> exportPackSummary(List<TrainingSpot> spots) async {
    if (spots.isEmpty) return;
    final buffer = StringBuffer();
    for (final spot in spots) {
      buffer.writeln(
          'ID: ${spot.tournamentId ?? '-'}, Buy-In: ${spot.buyIn ?? '-'}, Game: ${spot.gameType ?? '-'}, Tags: ${spot.tags.length}');
    }
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/spot_summary_${DateTime.now().millisecondsSinceEpoch}.txt');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'spot_summary.txt');
  }

  static Future<void> exportCsv(
    BuildContext context,
    List<TrainingSpot> spots, {
    String? successMessage,
  }) async {
    if (spots.isEmpty) return;

    final rows = <List<dynamic>>[];
    rows.add(['ID', 'Difficulty', 'Rating', 'Tags', 'Buy-in', 'ICM', 'Date']);
    final today = DateTime.now();
    final dateStr =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    for (final s in spots) {
      rows.add([
        s.tournamentId ?? '',
        s.difficulty,
        s.rating,
        s.tags.join(';'),
        s.buyIn ?? '',
        s.tags.contains('ICM') ? '1' : '0',
        dateStr,
      ]);
    }

    final csvStr = const ListToCsvConverter().convert(rows, eol: '\r\n');
    final bytes = Uint8List.fromList(utf8.encode(csvStr));
    final name = 'training_spots_${DateTime.now().millisecondsSinceEpoch}';
    try {
      await FileSaver.instance.saveAs(
        name: name,
        bytes: bytes,
        ext: 'csv',
        mimeType: MimeType.csv,
      );
      final msg =
          successMessage ?? 'Экспортировано ${spots.length} спотов в CSV';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка экспорта CSV')));
    }
  }

  static Future<List<TrainingSpot>?> importFromFile(
      BuildContext context, String path) async {
    final file = File(path);
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content);
      if (data is! List) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Неверный формат файла')));
        return null;
      }
      final spots = <TrainingSpot>[];
      for (final e in data) {
        if (e is Map) {
          try {
            spots.add(TrainingSpot.fromJson(Map<String, dynamic>.from(e)));
          } catch (_) {}
        }
      }
      if (spots.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Неверный формат файла')));
        return null;
      }
      return spots;
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ошибка чтения файла')));
      return null;
    }
  }

  static Future<List<TrainingSpot>?> pickPack(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return null;
    final path = result.files.single.path;
    if (path == null) return null;
    return importFromFile(context, path);
  }

  static Future<List<TrainingSpot>> importFromDrop(
      BuildContext context, DropDoneDetails details) async {
    final imported = <TrainingSpot>[];
    for (final item in details.files) {
      final path = item.path;
      if (path.toLowerCase().endsWith('.json')) {
        final spots = await importFromFile(context, path);
        if (spots != null) {
          imported.addAll(spots);
        }
      }
    }
    return imported;
  }
}

