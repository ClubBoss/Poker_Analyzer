import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'training_stats_service.dart';

class ProgressExportService {
  final TrainingStatsService stats;
  ProgressExportService({required this.stats});

  Future<File> exportCsv({bool weekly = false}) async {
    final rows = stats.progressRows(weekly: weekly);
    final csvStr = const ListToCsvConverter().convert(rows, eol: '\r\n');
    final dir = await getTemporaryDirectory();
    final mode = weekly ? 'weekly' : 'daily';
    final file = File('${dir.path}/progress_\${mode}_\${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvStr, encoding: utf8);
    return file;
  }

  Future<File> exportPdf({bool weekly = false}) async {
    final rows = stats.progressRows(weekly: weekly);
    final header = rows.first.cast<String>();
    final data = rows.skip(1).toList();
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Table.fromTextArray(headers: header, data: data);
        },
      ),
    );
    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final mode = weekly ? 'weekly' : 'daily';
    final file = File('${dir.path}/progress_\${mode}_\${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }
}
