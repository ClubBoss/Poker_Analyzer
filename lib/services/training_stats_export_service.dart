import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/session_log.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/hero_position.dart';

class TrainingStatsExportService {
  const TrainingStatsExportService();

  List<List<dynamic>> buildRows({
    required List<SessionLog> logs,
    required List<TrainingPackTemplateV2> library,
    DateTimeRange? range,
    HeroPosition? position,
    int? stack,
    String? tag,
  }) {
    final byId = {for (final t in library) t.id: t};
    final rows = <List<dynamic>>[
      ['Date', 'Hand ID', 'Stack', 'Hero Pos', 'Action', 'Correct', 'Tag'],
    ];
    for (final log in logs) {
      if (range != null) {
        if (log.completedAt.isBefore(range.start) ||
            log.completedAt.isAfter(range.end)) {
          continue;
        }
      }
      final tpl = byId[log.templateId];
      if (tpl == null) continue;
      final positions = tpl.positions.isNotEmpty
          ? tpl.positions.map(parseHeroPosition).toList()
          : [HeroPosition.unknown];
      final bb = tpl.bb;
      final tags = [for (final t in tpl.tags) t.toLowerCase()];
      if (position != null && !positions.contains(position)) continue;
      if (stack != null && bb != stack) continue;
      if (tag != null && !tags.contains(tag.toLowerCase())) continue;
      final total = log.correctCount + log.mistakeCount;
      final correct = log.correctCount;
      final date = log.completedAt.toIso8601String().split('T').first;
      final tagStr = tags.join('|');
      for (final pos in positions) {
        rows.add([
          date,
          tpl.id,
          bb,
          pos.label,
          '',
          '$correct/$total',
          tagStr,
        ]);
      }
    }
    return rows;
  }

  Future<File> exportCsv({
    required List<SessionLog> logs,
    required List<TrainingPackTemplateV2> library,
    DateTimeRange? range,
    HeroPosition? position,
    int? stack,
    String? tag,
  }) async {
    final rows = buildRows(
      logs: logs,
      library: library,
      range: range,
      position: position,
      stack: stack,
      tag: tag,
    );
    final csvStr = const ListToCsvConverter().convert(rows, eol: '\r\n');
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/training_stats_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvStr, encoding: utf8);
    return file;
  }

  Future<File> exportPdf({
    required List<SessionLog> logs,
    required List<TrainingPackTemplateV2> library,
    DateTimeRange? range,
    HeroPosition? position,
    int? stack,
    String? tag,
  }) async {
    final rows = buildRows(
      logs: logs,
      library: library,
      range: range,
      position: position,
      stack: stack,
      tag: tag,
    );
    final header = rows.first.cast<String>();
    final data = rows.skip(1).toList();
    int totalHands = 0;
    int correctHands = 0;
    for (final log in logs) {
      if (range != null) {
        if (log.completedAt.isBefore(range.start) ||
            log.completedAt.isAfter(range.end)) {
          continue;
        }
      }
      final tpl = library.firstWhere(
        (t) => t.id == log.templateId,
        orElse: () => TrainingPackTemplateV2(id: '', name: ''),
      );
      final positions = tpl.positions.isNotEmpty
          ? tpl.positions.map(parseHeroPosition).toList()
          : [HeroPosition.unknown];
      final tags = [for (final t in tpl.tags) t.toLowerCase()];
      if (position != null && !positions.contains(position)) continue;
      if (stack != null && tpl.bb != stack) continue;
      if (tag != null && !tags.contains(tag.toLowerCase())) continue;
      totalHands += log.correctCount + log.mistakeCount;
      correctHands += log.correctCount;
    }
    final acc = totalHands > 0 ? correctHands * 100 / totalHands : 0.0;

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Text('Training Stats', style: const pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 8),
            pw.Text('Total hands: $totalHands'),
            pw.Text('Accuracy: ${acc.toStringAsFixed(1)}%'),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(headers: header, data: data),
          ];
        },
      ),
    );
    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/training_stats_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }
}
