import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';

import '../models/saved_hand.dart';
import '../services/saved_hand_manager_service.dart';
import 'hand_history_review_screen.dart';
import '../widgets/saved_hand_tile.dart';

class MistakeRepeatScreen extends StatelessWidget {
  const MistakeRepeatScreen({super.key});

  Map<String, List<SavedHand>> _groupMistakes(List<SavedHand> hands) {
    final Map<String, List<SavedHand>> grouped = {};
    for (final h in hands) {
      final expected = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      if (expected != null &&
          gto != null &&
          expected.isNotEmpty &&
          gto.isNotEmpty &&
          expected != gto) {
        for (final tag in h.tags) {
          grouped.putIfAbsent(tag, () => []).add(h);
        }
      }
    }
    return grouped;
  }

  Future<void> _exportPdf(BuildContext context) async {
    final hands = context.read<SavedHandManagerService>().hands;
    final entries = _groupMistakes(hands)
        .entries
        .where((e) => e.value.length > 1)
        .toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    if (entries.isEmpty) return;

    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) {
          return [
            pw.Text('Повторы ошибок',
                style: pw.TextStyle(font: boldFont, fontSize: 24)),
            pw.SizedBox(height: 16),
            for (final e in entries) ...[
              pw.Text('${e.key} — ${e.value.length}',
                  style: pw.TextStyle(font: boldFont, fontSize: 16)),
              pw.SizedBox(height: 4),
              for (final h in e.value)
                pw.Bullet(text: h.name,
                    style: pw.TextStyle(font: regularFont)),
              pw.SizedBox(height: 12),
            ]
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final dir =
        await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final fileName =
        'mistake_repeats_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Файл сохранён: $fileName'),
          action: SnackBarAction(
            label: 'Открыть',
            onPressed: () => OpenFilex.open(file.path),
          ),
        ),
      );
    }
  }

  Future<void> _exportMarkdown(BuildContext context) async {
    final hands = context.read<SavedHandManagerService>().hands;
    final entries = _groupMistakes(hands)
        .entries
        .where((e) => e.value.length > 1)
        .toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    if (entries.isEmpty) return;

    final buffer = StringBuffer()
      ..writeln('# Повторы ошибок')
      ..writeln();
    for (final e in entries) {
      buffer.writeln('## ${e.key} (${e.value.length})');
      for (final h in e.value) {
        buffer.writeln('- ${h.name}');
      }
      buffer.writeln();
    }

    final dir =
        await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final fileName =
        'mistake_repeats_${DateTime.now().millisecondsSinceEpoch}.md';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(buffer.toString());

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Файл сохранён: $fileName'),
          action: SnackBarAction(
            label: 'Открыть',
            onPressed: () => OpenFilex.open(file.path),
          ),
        ),
      );
    }
  }

  Future<void> _showExportOptions(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Markdown'),
              onTap: () => Navigator.pop(ctx, 'md'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF'),
              onTap: () => Navigator.pop(ctx, 'pdf'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (result == 'md') {
      await _exportMarkdown(context);
    } else if (result == 'pdf') {
      await _exportPdf(context);
    }
  }


  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final grouped = _groupMistakes(hands);

    final entries = grouped.entries
        .where((e) => e.value.length > 1)
        .toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Повторы ошибок'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: 'Экспорт',
            onPressed: () => _showExportOptions(context),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.all(12),
                iconColor: Colors.white,
                collapsedIconColor: Colors.white,
                textColor: Colors.white,
                collapsedTextColor: Colors.white,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${entry.value.length}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                children: [
                  for (final hand in entry.value)
                    SavedHandTile(
                      hand: hand,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HandHistoryReviewScreen(hand: hand),
                          ),
                        );
                      },
                      onFavoriteToggle: () {
                        final manager =
                            context.read<SavedHandManagerService>();
                        final idx = manager.hands.indexOf(hand);
                        manager.update(idx,
                            hand.copyWith(isFavorite: !hand.isFavorite));
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
