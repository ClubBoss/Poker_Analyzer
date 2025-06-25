import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../services/goals_service.dart';
import 'goal_history_screen.dart';

class GoalsOverviewScreen extends StatelessWidget {
  const GoalsOverviewScreen({super.key});

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d.$m.${date.year}';
  }

  Future<void> _exportPdf(BuildContext context, List<Goal> goals) async {
    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Text('Мои цели', style: pw.TextStyle(font: boldFont, fontSize: 24)),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: const ['Цель', 'Прогресс', 'Создано', 'Завершено'],
            headerStyle: pw.TextStyle(font: boldFont),
            cellStyle: pw.TextStyle(font: regularFont),
            data: [
              for (final g in goals)
                [
                  g.title,
                  '${g.progress}/${g.target}',
                  _formatDate(g.createdAt),
                  g.completedAt != null ? _formatDate(g.completedAt!) : '-',
                ]
            ],
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'goals.pdf');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Файл сохранён: goals.pdf')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<GoalsService>();
    final accent = Theme.of(context).colorScheme.secondary;
    final goals = service.goals;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои цели'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _exportPdf(context, goals),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: goals.length,
        itemBuilder: (context, index) {
          final g = goals[index];
          final progress = (g.progress / g.target).clamp(0.0, 1.0);
          final completed = g.completedAt != null;
          return InkWell(
            onTap: completed
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => GoalHistoryScreen(index: index)),
                    )
                : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (g.icon != null) ...[
                    Icon(g.icon, color: accent),
                    const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${g.progress}/${g.target}'),
                      const SizedBox(height: 4),
                      Text('Установлено: ${_formatDate(g.createdAt)}',
                          style: const TextStyle(color: Colors.white70)),
                      if (completed)
                        Text('Завершено: ${_formatDate(g.completedAt!)}',
                            style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  completed ? Icons.check_circle : Icons.timelapse,
                  color: completed ? Colors.green : Colors.grey,
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
