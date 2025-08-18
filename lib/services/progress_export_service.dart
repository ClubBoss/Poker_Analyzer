import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'training_stats_service.dart';
import '../models/saved_hand.dart';

class ProgressExportService {
  final TrainingStatsService stats;
  ProgressExportService({required this.stats});

  Future<File> exportCsv({bool weekly = false}) async {
    final rows = stats.progressRows(weekly: weekly);
    final csvStr = const ListToCsvConverter().convert(rows, eol: '\r\n');
    final dir = await getTemporaryDirectory();
    final mode = weekly ? 'weekly' : 'daily';
    final file = File(
      '${dir.path}/progress_\${mode}_\${DateTime.now().millisecondsSinceEpoch}.csv',
    );
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
    final file = File(
      '${dir.path}/progress_\${mode}_\${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(bytes);
    return file;
  }

  List<List<dynamic>> _evIcmRows(List<SavedHand> hands, bool weekly) {
    final ev = weekly ? stats.evWeekly(hands) : stats.evDaily(hands);
    final icm = weekly ? stats.icmWeekly(hands) : stats.icmDaily(hands);
    final mistakes = weekly ? stats.mistakesWeekly() : stats.mistakesDaily();
    final dates = {
      for (final e in ev) e.key,
      for (final e in icm) e.key,
      for (final e in mistakes) e.key,
    }.toList()..sort();
    final evMap = {for (final e in ev) e.key: e.value};
    final icmMap = {for (final e in icm) e.key: e.value};
    final mMap = {for (final e in mistakes) e.key: e.value};
    return [
      ['Date', 'EV', 'ICM', 'Mistakes'],
      for (final d in dates)
        [
          d.toIso8601String().split('T').first,
          evMap[d] != null ? evMap[d]!.toStringAsFixed(2) : '',
          icmMap[d] != null ? icmMap[d]!.toStringAsFixed(3) : '',
          mMap[d] ?? 0,
        ],
    ];
  }

  Future<File> exportEvIcmCsv(
    List<SavedHand> hands, {
    bool weekly = false,
  }) async {
    final rows = _evIcmRows(hands, weekly);
    final csvStr = const ListToCsvConverter().convert(rows, eol: '\r\n');
    final dir = await getTemporaryDirectory();
    final mode = weekly ? 'weekly' : 'daily';
    final file = File(
      '${dir.path}/ev_icm_\${mode}_\${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(csvStr, encoding: utf8);
    return file;
  }

  Future<File> exportEvIcmPdf(
    List<SavedHand> hands, {
    bool weekly = false,
  }) async {
    final rows = _evIcmRows(hands, weekly);
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
    final file = File(
      '${dir.path}/ev_icm_\${mode}_\${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(bytes);
    return file;
  }
}
