import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:io';

import '../helpers/date_utils.dart';
import '../helpers/street_name_helper.dart';

import '../services/saved_hand_manager_service.dart';
import '../services/evaluation_executor_service.dart';
import '../widgets/saved_hand_list_view.dart';
import 'hand_history_review_screen.dart';

/// Displays a list of streets sorted by mistake count.
///
/// Information is pulled from [EvaluationExecutorService.summarizeHands]. Each
/// tile shows how many errors were made on that street. Selecting a street opens
/// a filtered [SavedHandListView] showing only the mistaken hands for the chosen
/// street.
class StreetMistakeOverviewScreen extends StatelessWidget {
  const StreetMistakeOverviewScreen({super.key});

  Future<void> _exportPdf(
      BuildContext context, List<MapEntry<String, int>> entries) async {
    if (entries.isEmpty) return;

    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();

    final pdf = pw.Document();
    final date = formatDateTime(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Text('Ошибки по улицам',
              style: pw.TextStyle(font: boldFont, fontSize: 24)),
          pw.SizedBox(height: 8),
          pw.Text(date, style: pw.TextStyle(font: regularFont)),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: const ['Улица', 'Ошибки'],
            data: [for (final e in entries) [e.key, e.value.toString()]],
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/street_mistakes_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], text: 'street_mistakes.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final summary =
        context.read<EvaluationExecutorService>().summarizeHands(hands);
    final entries = summary.streetBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ошибки по улицам'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'PDF',
            onPressed: () => _exportPdf(context, entries),
          ),
        ],
      ),
      body: entries.isEmpty
          ? const Center(
              child: Text(
                'Ошибок нет',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final e in entries)
                  ListTile(
                    title:
                        Text(e.key, style: const TextStyle(color: Colors.white)),
                    trailing: Text(e.value.toString(),
                        style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _StreetMistakeHandsScreen(street: e.key),
                        ),
                      );
                    },
                  ),
              ],
            ),
    );
  }
}

class _StreetMistakeHandsScreen extends StatelessWidget {
  final String street;
  const _StreetMistakeHandsScreen({required this.street});

  @override
  Widget build(BuildContext context) {
    final allHands = context.watch<SavedHandManagerService>().hands;
    final filtered = [
      for (final h in allHands)
        if (streetName(h.boardStreet) == street) h
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(street),
        centerTitle: true,
      ),
      body: SavedHandListView(
        hands: filtered,
        accuracy: 'errors',
        title: 'Ошибки: $street',
        onTap: (hand) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HandHistoryReviewScreen(hand: hand),
            ),
          );
        },
      ),
    );
  }
}

