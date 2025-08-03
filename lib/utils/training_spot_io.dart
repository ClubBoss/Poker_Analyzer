import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/training_spot.dart';

Future<void> exportPack(BuildContext context, List<TrainingSpot> spots) async {
  if (spots.isEmpty) return;
  const encoder = JsonEncoder.withIndent('  ');
  final jsonStr = encoder.convert([for (final s in spots) s.toJson()]);
  final dir = await getTemporaryDirectory();
  final file = File(
      '${dir.path}/training_spots_${DateTime.now().millisecondsSinceEpoch}.json');
  await file.writeAsString(jsonStr);
  await Share.shareXFiles([XFile(file.path)], text: 'training_spots.json');
}

Future<void> exportNamedPack(
    BuildContext context, List<TrainingSpot> spots, String name) async {
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

Future<void> exportPackSummary(
    BuildContext context, List<TrainingSpot> spots) async {
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

Future<void> exportCsv(BuildContext context, List<TrainingSpot> spots,
    {String? successMessage}) async {
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
    final msg = successMessage ??
        'Экспортировано ${spots.length} спотов в CSV';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  } catch (_) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Ошибка экспорта CSV')));
  }
}

Future<List<TrainingSpot>> importFromFile(BuildContext context, String path) async {
  final file = File(path);
  try {
    final content = await file.readAsString();
    final data = jsonDecode(content);
    if (data is! List) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Неверный формат файла')));
      return [];
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
      return [];
    }
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Импортировано спотов: ${spots.length}')));
    return spots;
  } catch (_) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Ошибка чтения файла')));
    return [];
  }
}

Future<List<TrainingSpot>> importPack(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  if (result == null || result.files.isEmpty) return [];
  final path = result.files.single.path;
  if (path == null) return [];
  return await importFromFile(context, path);
}
