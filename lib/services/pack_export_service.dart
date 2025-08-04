import 'dart:io';
import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/v2/training_pack_template.dart';
import '../models/saved_hand.dart';

class PackExportService {
  static Future<File> exportToCsv(TrainingPackTemplate tpl) async {
    final rows = <List<dynamic>>[
      [
        'Title',
        'HeroPosition',
        'HeroHand',
        'StackBB',
        'StacksBB',
        'HeroIndex',
        'CallsMask',
        'EV_BB',
        'ICM_EV',
        'Tags'
      ],
    ];
    for (final spot in tpl.spots) {
      final hand = spot.hand;
      final stacks = [
        for (var i = 0; i < hand.playerCount; i++)
          hand.stacks['$i']?.toString() ?? ''
      ].join('/');
      final pre = hand.actions[0] ?? [];
      final callsMask = hand.playerCount == 2
          ? ''
          : [
              for (var i = 0; i < hand.playerCount; i++)
                pre.any((a) => a.playerIndex == i && a.action == 'call')
                    ? '1'
                    : '0'
            ].join();
      rows.add([
        spot.title,
        hand.position.label,
        hand.heroCards,
        hand.stacks['${hand.heroIndex}']?.toString() ?? '',
        stacks,
        hand.heroIndex,
        callsMask,
        spot.heroEv?.toStringAsFixed(1) ?? '',
        spot.heroIcmEv?.toStringAsFixed(3) ?? '',
        spot.tags.join('|'),
      ]);
    }
    final csvStr = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final base = _toSnakeCase(tpl.name);
    var path = '${dir.path}/$base.csv';
    if (await File(path).exists()) {
      path = '${dir.path}/$base_${DateTime.now().millisecondsSinceEpoch}.csv';
    }
    final file = File(path);
    await file.writeAsString(csvStr);
    await _shareFile(file);
    return file;
  }

  static Future<File> exportToPdf(TrainingPackTemplate tpl) async {
    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Text(tpl.name,
                style: pw.TextStyle(font: boldFont, fontSize: 24)),
            pw.SizedBox(height: 16),
            for (int i = 0; i < tpl.spots.length; i++)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Spot ${i + 1}',
                      style: pw.TextStyle(font: boldFont, fontSize: 18)),
                  pw.Bullet(
                    text: 'Position: ${tpl.spots[i].hand.position.label}',
                    style: pw.TextStyle(font: regularFont),
                  ),
                  pw.Bullet(
                    text: 'Cards: ${tpl.spots[i].hand.heroCards}',
                    style: pw.TextStyle(font: regularFont),
                  ),
                  pw.Bullet(
                    text:
                        'EV: ${tpl.spots[i].heroEv?.toStringAsFixed(2) ?? ''}',
                    style: pw.TextStyle(font: regularFont),
                  ),
                  if (tpl.spots[i].tags.isNotEmpty)
                    pw.Bullet(
                      text: 'Tags: ${tpl.spots[i].tags.join(', ')}',
                      style: pw.TextStyle(font: regularFont),
                    ),
                  pw.SizedBox(height: 8),
                ],
              ),
          ];
        },
      ),
    );
    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final base = _toSnakeCase(tpl.name);
    var path = '${dir.path}/$base.pdf';
    if (await File(path).exists()) {
      path = '${dir.path}/${base}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    }
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    await _shareFile(file);
    return file;
  }

  static Future<File> exportBundle(TrainingPackTemplate tpl) async {
    final pdf = await exportToPdf(tpl);
    final jsonData = utf8.encode(jsonEncode(tpl.toJson()));
    final pdfBytes = await pdf.readAsBytes();
    final archive = Archive()
      ..addFile(ArchiveFile('template.json', jsonData.length, jsonData))
      ..addFile(ArchiveFile('preview.pdf', pdfBytes.length, pdfBytes));
    final bytes = ZipEncoder().encode(archive);
    final dir = await getTemporaryDirectory();
    final base = _toSnakeCase(tpl.name);
    var path = '${dir.path}/$base.pka';
    if (await File(path).exists()) {
      path = '${dir.path}/$base_${DateTime.now().millisecondsSinceEpoch}.pka';
    }
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    await _shareFile(file);
    return file;
  }

  static String exportShareLink(TrainingPackTemplate tpl) {
    final jsonStr = jsonEncode(tpl.toJson());
    return base64Url.encode(utf8.encode(jsonStr));
  }

  static Future<File> exportSessionCsv(
      List<SavedHand> hands, List<double> evs, List<double> icms) async {
    final rows = <List<dynamic>>[
      ['#', 'Name', 'HeroPos', 'Hero', 'GTO', 'EV', 'ICM', 'Tags']
    ];
    for (var i = 0; i < hands.length; i++) {
      final h = hands[i];
      rows.add([
        i + 1,
        h.name,
        h.heroPosition,
        h.expectedAction ?? '',
        h.gtoAction ?? '',
        evs[i].toStringAsFixed(2),
        icms[i].toStringAsFixed(2),
        h.tags.join('|'),
      ]);
    }
    final csvStr = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    var path = '${dir.path}/session_report.csv';
    if (await File(path).exists()) {
      path =
          '${dir.path}/session_report_${DateTime.now().millisecondsSinceEpoch}.csv';
    }
    final file = File(path);
    await file.writeAsString(csvStr);
    await _shareFile(file);
    return file;
  }

  static Future<File> exportSessionPdf(
      List<SavedHand> hands, List<double> evs, List<double> icms) async {
    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          int correct = 0;
          int mistakes = 0;
          for (final h in hands) {
            final exp = h.expectedAction?.trim().toLowerCase();
            final gto = h.gtoAction?.trim().toLowerCase();
            if (exp != null && gto != null) {
              if (exp == gto) {
                correct++;
              } else {
                mistakes++;
              }
            }
          }
          final accuracy = correct + mistakes > 0
              ? correct * 100 / (correct + mistakes)
              : 0.0;
          final preEv = evs.isNotEmpty ? evs.first : 0.0;
          final postEv = evs.isNotEmpty ? evs.last : 0.0;
          final preIcm = icms.isNotEmpty ? icms.first : 0.0;
          final postIcm = icms.isNotEmpty ? icms.last : 0.0;
          return [
            pw.Text('Session Report',
                style: pw.TextStyle(font: boldFont, fontSize: 24)),
            pw.SizedBox(height: 16),
            pw.Text('Hands: ${hands.length}',
                style: pw.TextStyle(font: regularFont)),
            pw.Text('Accuracy: ${accuracy.toStringAsFixed(1)}%',
                style: pw.TextStyle(font: regularFont)),
            pw.Text('Mistakes: $mistakes',
                style: pw.TextStyle(font: regularFont)),
            pw.Text(
                'EV: ${preEv.toStringAsFixed(2)} ➜ ${postEv.toStringAsFixed(2)}',
                style: pw.TextStyle(font: regularFont)),
            pw.Text(
                'ICM: ${preIcm.toStringAsFixed(2)} ➜ ${postIcm.toStringAsFixed(2)}',
                style: pw.TextStyle(font: regularFont)),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: const ['#', 'Name', 'Hero', 'GTO', 'EV', 'ICM'],
              data: [
                for (var i = 0; i < hands.length; i++)
                  [
                    '${i + 1}',
                    hands[i].name,
                    hands[i].expectedAction ?? '',
                    hands[i].gtoAction ?? '',
                    evs[i].toStringAsFixed(2),
                    icms[i].toStringAsFixed(2),
                  ]
              ],
            ),
          ];
        },
      ),
    );
    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    var path = '${dir.path}/session_report.pdf';
    if (await File(path).exists()) {
      path =
          '${dir.path}/session_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    }
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    await _shareFile(file);
    return file;
  }

  static String toMarkdown(TrainingPackTemplate tpl) {
    final spots = tpl.spots;
    final total = spots.length;
    final evCovered = spots.where((s) => s.heroEv != null).length;
    final icmCovered = spots.where((s) => s.heroIcmEv != null).length;
    final buffer = StringBuffer()
      ..writeln('# ${tpl.name}')
      ..writeln('- **ID:** ${tpl.id}')
      ..writeln('- **Spots:** $total')
      ..writeln(
          '- **EV coverage:** ${total == 0 ? 0 : (evCovered / total * 100).toStringAsFixed(1)}%')
      ..writeln(
          '- **ICM coverage:** ${total == 0 ? 0 : (icmCovered / total * 100).toStringAsFixed(1)}%')
      ..writeln(
          '- **Created:** ${DateFormat('yyyy-MM-dd').format(tpl.createdAt)}');
    final tags = tpl.tags.toSet().where((e) => e.isNotEmpty).toList();
    if (tags.isNotEmpty) buffer.writeln('- **Tags:** ${tags.join(', ')}');
    final preview = spots.where((s) => s.heroEv != null).take(5);
    if (preview.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('|Pos|Hero|Board|EV|Tags|')
        ..writeln('|---|---|---|---|---|');
      for (final spot in preview) {
        buffer.writeln(
            '|${spot.hand.position.name}|${spot.hand.heroCards}|${spot.hand.board.join(' ')}|${spot.heroEv!.toStringAsFixed(2)}|${spot.tags.join(', ')}|');
      }
    }
    return buffer.toString().trimRight();
  }

  static Future<void> _shareFile(File file) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await Permission.storage.request();
    }
    await Share.shareXFiles([XFile(file.path)]);
  }

  static String _toSnakeCase(String input) {
    final snake = input
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp('_+'), '_')
        .toLowerCase();
    return snake.startsWith('_') ? snake.substring(1) : snake;
  }
}
