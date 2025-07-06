import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import '../models/v2/training_pack_template.dart';

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
            pw.Text(tpl.name, style: pw.TextStyle(font: boldFont, fontSize: 24)),
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
                    text: 'EV: ${tpl.spots[i].heroEv?.toStringAsFixed(2) ?? ''}',
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
    return file;
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
