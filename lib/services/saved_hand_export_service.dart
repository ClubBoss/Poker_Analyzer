import 'dart:io';
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../helpers/date_utils.dart';
import '../helpers/export_utils.dart';
import '../models/saved_hand.dart';
import 'saved_hand_manager_service.dart';
import 'saved_hand_stats_service.dart';

class SavedHandExportService {
  SavedHandExportService({
    required SavedHandManagerService manager,
    required SavedHandStatsService stats,
  })  : _manager = manager,
        _stats = stats;

  final SavedHandManagerService _manager;
  final SavedHandStatsService _stats;

  List<SavedHand> get _hands => _manager.hands;

  Future<void> _shareFile(File file) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await Permission.storage.request();
    }
    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<String?> exportAllHandsMarkdown() async {
    if (_hands.isEmpty) return null;
    final buffer = StringBuffer();
    for (final hand in _hands) {
      buffer.write(ExportUtils.handMarkdown(hand));
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/all_saved_hands.md');
    await file.writeAsString(buffer.toString());
    return file.path;
  }

  Future<String?> exportAllHandsPdf() async {
    if (_hands.isEmpty) return null;

    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            for (final hand in _hands) ...ExportUtils.handPdfWidgets(
              hand,
              regularFont,
              boldFont,
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/all_saved_hands.pdf');
    await file.writeAsBytes(bytes);
    await _shareFile(file);
    return file.path;
  }

  Future<String?> exportAllSessionsMarkdown(Map<int, String> notes) async {
    if (_hands.isEmpty) return null;

    String durToStr(Duration d) => formatDuration(d);

    final grouped = _stats.handsBySession().entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final buffer = StringBuffer();

    for (final entry in grouped) {
      final id = entry.key;
      final sessionHands = List<SavedHand>.from(entry.value)
        ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
      if (sessionHands.isEmpty) continue;

      final stats = _stats.sessionStats(sessionHands);
      final note = notes[id];

      buffer.writeln('## Сессия $id');
      buffer.writeln('- Дата: ${formatDateTime(stats.end)}');
      buffer.writeln('- Длительность: ${durToStr(stats.duration)}');
      buffer.writeln('- Раздач: ${stats.count}');
      buffer.writeln('- Верно: ${stats.correct}');
      buffer.writeln('- Ошибки: ${stats.incorrect}');
      final winrate = stats.winrate;
      if (winrate != null) {
        buffer.writeln('- Winrate: ${winrate.toStringAsFixed(1)}%');
      }
      if (note != null && note.trim().isNotEmpty) {
        buffer.writeln('- Заметка: ${note.trim()}');
      }
      buffer.writeln();
      for (final hand in sessionHands) {
        buffer.write(ExportUtils.handMarkdown(hand, level: 3));
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/training_summary.md');
    await file.writeAsString(buffer.toString());
    return file.path;
  }

  Future<String?> exportAllSessionsPdf(Map<int, String> notes) async {
    if (_hands.isEmpty) return null;

    String durToStr(Duration d) => formatDuration(d);

    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();

    final grouped = _stats.handsBySession().entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            for (final entry in grouped) ...[
              () {
                final id = entry.key;
                final sessionHands = List<SavedHand>.from(entry.value)
                  ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
                final stats = _stats.sessionStats(sessionHands);
                final note = notes[id];

                return [
                  pw.Text('Сессия $id',
                      style: pw.TextStyle(font: boldFont, fontSize: 20)),
                  pw.SizedBox(height: 4),
                  pw.Text('Дата: ${formatDateTime(stats.end)}',
                      style: pw.TextStyle(font: regularFont)),
                  pw.Text('Длительность: ${durToStr(stats.duration)}',
                      style: pw.TextStyle(font: regularFont)),
                  pw.Text(
                      'Раздач: ${stats.count} • Верно: ${stats.correct} • Ошибки: ${stats.incorrect}',
                      style: pw.TextStyle(font: regularFont)),
                  if (stats.winrate != null)
                    pw.Text('Winrate: ${stats.winrate!.toStringAsFixed(1)}%',
                        style: pw.TextStyle(font: regularFont)),
                  if (note != null && note.trim().isNotEmpty)
                    pw.Text('Заметка: ${note.trim()}',
                        style: pw.TextStyle(font: regularFont)),
                  pw.SizedBox(height: 8),
                  for (final hand in sessionHands)
                    ...ExportUtils.handPdfWidgets(
                      hand,
                      regularFont,
                      boldFont,
                      titleSize: 16,
                    ),
                  pw.Divider(),
                ];
              }(),
            ],
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/training_summary.pdf');
    await file.writeAsBytes(bytes);
    await _shareFile(file);
    return file.path;
  }

  Future<String?> exportSessionsMarkdown(
      List<int> sessionIds, Map<int, String> notes) async {
    if (sessionIds.isEmpty) return null;

    String durToStr(Duration d) => formatDuration(d);

    final grouped = _stats.handsBySession();
    final ids = List<int>.from(sessionIds)..sort();
    final buffer = StringBuffer();

    for (final id in ids) {
      final sessionHands = grouped[id];
      if (sessionHands == null || sessionHands.isEmpty) continue;
      final handsList = List<SavedHand>.from(sessionHands)
        ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
      final stats = _stats.sessionStats(handsList);
      final note = notes[id];

      buffer.writeln('## Сессия $id');
      buffer.writeln('- Дата: ${formatDateTime(stats.end)}');
      buffer.writeln('- Длительность: ${durToStr(stats.duration)}');
      buffer.writeln('- Раздач: ${stats.count}');
      buffer.writeln('- Верно: ${stats.correct}');
      buffer.writeln('- Ошибки: ${stats.incorrect}');
      final winrate = stats.winrate;
      if (winrate != null) {
        buffer.writeln('- Winrate: ${winrate.toStringAsFixed(1)}%');
      }
      if (note != null && note.trim().isNotEmpty) {
        buffer.writeln('- Заметка: ${note.trim()}');
      }
      buffer.writeln();
      for (final hand in handsList) {
        buffer.write(ExportUtils.handMarkdown(hand, level: 3));
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/training_summary_filtered.md');
    await file.writeAsString(buffer.toString());
    return file.path;
  }

  Future<String?> exportSessionsPdf(
      List<int> sessionIds, Map<int, String> notes) async {
    if (sessionIds.isEmpty) return null;

    String durToStr(Duration d) => formatDuration(d);

    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();

    final grouped = _stats.handsBySession();
    final ids = List<int>.from(sessionIds)..sort();

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            for (final id in ids)
              if (grouped[id] != null && grouped[id]!.isNotEmpty) ...[
                () {
                  final handsList = List<SavedHand>.from(grouped[id]!)
                    ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
                  final stats = _stats.sessionStats(handsList);
                  final note = notes[id];

                  return [
                    pw.Text('Сессия $id',
                        style: pw.TextStyle(font: boldFont, fontSize: 20)),
                    pw.SizedBox(height: 4),
                    pw.Text('Дата: ${formatDateTime(stats.end)}',
                        style: pw.TextStyle(font: regularFont)),
                    pw.Text('Длительность: ${durToStr(stats.duration)}',
                        style: pw.TextStyle(font: regularFont)),
                    pw.Text(
                        'Раздач: ${stats.count} • Верно: ${stats.correct} • Ошибки: ${stats.incorrect}',
                        style: pw.TextStyle(font: regularFont)),
                    if (stats.winrate != null)
                      pw.Text('Winrate: ${stats.winrate!.toStringAsFixed(1)}%',
                          style: pw.TextStyle(font: regularFont)),
                    if (note != null && note.trim().isNotEmpty)
                      pw.Text('Заметка: ${note.trim()}',
                          style: pw.TextStyle(font: regularFont)),
                    pw.SizedBox(height: 8),
                    for (final hand in handsList)
                      ...ExportUtils.handPdfWidgets(
                        hand,
                        regularFont,
                        boldFont,
                        titleSize: 16,
                      ),
                    pw.Divider(),
                  ];
                }(),
              ],
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/training_summary_filtered.pdf');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<String?> exportAllSessionsCsv(Map<int, String> notes) async {
    if (_hands.isEmpty) return null;


    final grouped = _stats.handsBySession().entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final rows = <List<dynamic>>[
      ['Дата', 'Длительность', 'Раздач', 'Верно', 'EV', 'ICM']
    ];

    for (final entry in grouped) {
      final list = List<SavedHand>.from(entry.value)
        ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
      if (list.isEmpty) continue;
      final stats = _stats.sessionStats(list);
      rows.add(ExportUtils.csvRow(
        stats.end,
        stats.duration,
        stats.count,
        stats.correct,
        stats.evAvg,
        stats.icmAvg,
      ));
    }

    final csv = const ListToCsvConverter(fieldDelimiter: ';')
        .convert(rows, eol: '\r\n');
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/training_summary.csv');
    await file.writeAsString(csv);
    return file.path;
  }

  Future<String?> exportSessionsCsv(
      List<int> sessionIds, Map<int, String> notes) async {
    if (sessionIds.isEmpty) return null;


    final grouped = _stats.handsBySession();
    final ids = List<int>.from(sessionIds)..sort();
    final rows = <List<dynamic>>[
      ['Дата', 'Длительность', 'Раздач', 'Верно', 'EV', 'ICM']
    ];

    for (final id in ids) {
      final sessionHands = grouped[id];
      if (sessionHands == null || sessionHands.isEmpty) continue;
      final list = List<SavedHand>.from(sessionHands)
        ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
      final stats = _stats.sessionStats(list);
      rows.add(ExportUtils.csvRow(
        stats.end,
        stats.duration,
        stats.count,
        stats.correct,
        stats.evAvg,
        stats.icmAvg,
      ));
    }

    final csv = const ListToCsvConverter(fieldDelimiter: ';')
        .convert(rows, eol: '\r\n');
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/training_summary_filtered.csv');
    await file.writeAsString(csv);
    return file.path;
  }

  Future<String?> exportSessionHandsMarkdown(int sessionId, {String? note}) async {
    final sessionHands =
        _hands.where((h) => h.sessionId == sessionId).toList();
    if (sessionHands.isEmpty) return null;
    final buffer = StringBuffer();
    if (note != null && note.trim().isNotEmpty) {
      buffer.writeln(note.trim());
      buffer.writeln();
    }
    for (final hand in sessionHands) {
      buffer.write(ExportUtils.handMarkdown(hand));
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/session_$sessionId.md');
    await file.writeAsString(buffer.toString());
    return file.path;
  }

  Future<String?> exportSessionHandsPdf(int sessionId, {String? note}) async {
    final sessionHands =
        _hands.where((h) => h.sessionId == sessionId).toList();
    if (sessionHands.isEmpty) return null;

    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            if (note != null && note.trim().isNotEmpty) ...[
              pw.Text(note.trim(), style: pw.TextStyle(font: regularFont)),
              pw.SizedBox(height: 12),
            ],
            for (final hand in sessionHands)
              ...ExportUtils.handPdfWidgets(
                hand,
                regularFont,
                boldFont,
              )
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/session_$sessionId.pdf');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<String?> exportSessionsArchive({bool pdf = false}) async {
    if (_hands.isEmpty) return null;

    String folder0(DateTime d) {
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '$y-$m-$day';
    }

    final archive = Archive();
    final grouped = _stats.handsBySession();
    for (final entry in grouped.entries) {
      final id = entry.key;
      final list = List<SavedHand>.from(entry.value)
        ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
      if (list.isEmpty) continue;
      final folder = folder0(list.first.savedAt);
      final path = pdf
          ? await exportSessionHandsPdf(id)
          : await exportSessionHandsMarkdown(id);
      if (path == null) continue;
      final file = File(path);
      final data = await file.readAsBytes();
      final ext = pdf ? 'pdf' : 'md';
      final name = '$folder/session_$id.$ext';
      archive.addFile(ArchiveFile(name, data.length, data));
      await file.delete();
    }

    final bytes = ZipEncoder().encode(archive);
    final dir = await getApplicationDocumentsDirectory();
    final out = File(
        '${dir.path}/saved_hands_archive_${DateTime.now().millisecondsSinceEpoch}.zip');
    await out.writeAsBytes(bytes);
    return out.path;
  }
}

