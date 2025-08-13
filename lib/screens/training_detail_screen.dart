import 'package:flutter/material.dart';

import '../helpers/date_utils.dart';
import '../models/training_result.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../widgets/sync_status_widget.dart';

class TrainingDetailScreen extends StatelessWidget {
  final TrainingResult result;
  final Future<void> Function() onDelete;
  final Future<void> Function(BuildContext) onEditTags;
  final Future<void> Function(BuildContext) onEditAccuracy;

  const TrainingDetailScreen({
    super.key,
    required this.result,
    required this.onDelete,
    required this.onEditTags,
    required this.onEditAccuracy,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Session?'),
          content: const Text('Are you sure you want to delete this session?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirm ?? false) {
      await onDelete();
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    }
  }

  Future<void> _exportPdf() async {
    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();

    final incorrect = result.total - result.correct;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Date: ${formatDateTime(result.date)}',
                  style: pw.TextStyle(font: regularFont)),
              pw.SizedBox(height: 16),
              if (result.total > 0)
                pw.Chart(
                  grid: pw.PieGrid(),
                  datasets: [
                    pw.PieDataSet(
                      value: result.correct.toDouble(),
                      color: PdfColors.green,
                      legend: 'Correct',
                    ),
                    pw.PieDataSet(
                      value: incorrect.toDouble(),
                      color: PdfColors.red,
                      legend: 'Incorrect',
                    ),
                  ],
                ),
              pw.SizedBox(height: 16),
              pw.Text('Total hands: ${result.total}',
                  style: pw.TextStyle(font: regularFont)),
              pw.Text('Correct answers: ${result.correct}',
                  style: pw.TextStyle(font: regularFont)),
              pw.Text('Accuracy: ${result.accuracy.toStringAsFixed(1)}%',
                  style: pw.TextStyle(font: boldFont)),
              if (result.tags.isNotEmpty) pw.SizedBox(height: 16),
              if (result.tags.isNotEmpty)
                pw.Wrap(
                  spacing: 4,
                  children: [
                    for (final tag in result.tags)
                      pw.Container(
                        padding: const pw.EdgeInsets.all(2),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(tag,
                            style: pw.TextStyle(font: regularFont)),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'session_${result.date.millisecondsSinceEpoch}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = result.accuracy.toStringAsFixed(1);
    final incorrect = result.total - result.correct;
    final total = result.total;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date: ${formatDateTime(result.date)}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            if (total > 0)
              PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      value: result.correct.toDouble(),
                      color: Colors.green,
                      title:
                          '${(result.correct * 100 / total).toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(color: Colors.white),
                    ),
                    PieChartSectionData(
                      value: incorrect.toDouble(),
                      color: Colors.red,
                      title: '${(incorrect * 100 / total).toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Total hands: ${result.total}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Correct answers: ${result.correct}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Accuracy: $accuracy%',
              style: const TextStyle(color: Colors.greenAccent),
            ),
            const SizedBox(height: 16),
            const Text('Tags:', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            if (result.tags.isEmpty)
              const Text('No tags', style: TextStyle(color: Colors.white70))
            else
              Wrap(
                spacing: 4,
                children: [
                  for (final tag in result.tags)
                    Chip(
                      label: Text(tag),
                    ),
                ],
              ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await onEditTags(context);
                      // ignore: use_build_context_synchronously
                      Navigator.pop(context);
                    },
                    child: const Text('Edit Tags'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => _confirmDelete(context),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                await onEditAccuracy(context);
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              },
              child: const Text('Edit Accuracy'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _exportPdf,
              child: const Text('Export to PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
