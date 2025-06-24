import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:poker_ai_analyzer/models/saved_hand.dart';
import 'package:poker_ai_analyzer/import_export/training_generator.dart';
import 'package:poker_ai_analyzer/widgets/replay_spot_widget.dart';
import '../services/saved_hand_manager_service.dart';

/// Displays a saved hand with simple playback controls.
/// Shows GTO recommendation and range group when available.
class HandHistoryReviewScreen extends StatefulWidget {
  final SavedHand hand;

  const HandHistoryReviewScreen({super.key, required this.hand});

  @override
  State<HandHistoryReviewScreen> createState() => _HandHistoryReviewScreenState();
}

class _HandHistoryReviewScreenState extends State<HandHistoryReviewScreen> {
  String? _selectedAction;
  late TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(text: widget.hand.comment ?? '');
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _saveComment(String text) async {
    final manager = context.read<SavedHandManagerService>();
    final index = manager.hands.indexOf(widget.hand);
    if (index >= 0) {
      final updated = widget.hand.copyWith(
        comment: text.trim().isNotEmpty ? text.trim() : null,
      );
      await manager.update(index, updated);
    }
  }

  Future<void> _exportMarkdown() async {
    final buffer = StringBuffer();
    buffer.writeln('## ${widget.hand.name}');
    if (_selectedAction != null) {
      buffer.writeln('- Выбор пользователя: $_selectedAction');
    }
    if (widget.hand.gtoAction != null && widget.hand.gtoAction!.isNotEmpty) {
      buffer.writeln('- GTO: ${widget.hand.gtoAction}');
    }
    if (widget.hand.rangeGroup != null && widget.hand.rangeGroup!.isNotEmpty) {
      buffer.writeln('- Группа: ${widget.hand.rangeGroup}');
    }
    final comment = _commentController.text.trim();
    if (comment.isNotEmpty) {
      buffer.writeln('- Комментарий: $comment');
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/hand_export.md');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'hand_export.md');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Файл сохранён: hand_export.md')),
      );
    }
  }

  Future<void> _exportPdf() async {
    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(widget.hand.name,
                  style: pw.TextStyle(font: boldFont, fontSize: 24)),
              pw.SizedBox(height: 16),
              if (_selectedAction != null)
                pw.Text('Выбор пользователя: $_selectedAction',
                    style: pw.TextStyle(font: regularFont)),
              if (widget.hand.gtoAction != null &&
                  widget.hand.gtoAction!.isNotEmpty)
                pw.Text('GTO: ${widget.hand.gtoAction}',
                    style: pw.TextStyle(font: regularFont)),
              if (widget.hand.rangeGroup != null &&
                  widget.hand.rangeGroup!.isNotEmpty)
                pw.Text('Группа: ${widget.hand.rangeGroup}',
                    style: pw.TextStyle(font: regularFont)),
              if (_commentController.text.trim().isNotEmpty)
                pw.Text('Комментарий: ${_commentController.text.trim()}',
                    style: pw.TextStyle(font: regularFont)),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/hand_export.pdf');
    await file.writeAsBytes(bytes);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Файл сохранён: hand_export.pdf')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final spot = TrainingGenerator().generateFromSavedHand(widget.hand);
    final gto = widget.hand.gtoAction;
    final group = widget.hand.rangeGroup;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hand.name),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReplaySpotWidget(spot: spot),
            const SizedBox(height: 12),
            if ((gto != null && gto.isNotEmpty) ||
                (group != null && group.isNotEmpty))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (gto != null && gto.isNotEmpty)
                    Text('Рекомендовано: $gto',
                        style: const TextStyle(color: Colors.white)),
                  if (group != null && group.isNotEmpty)
                    Text('Группа: $group',
                        style: const TextStyle(color: Colors.white)),
                ],
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              onChanged: _saveComment,
              maxLines: null,
              minLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Комментарий',
                labelStyle: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _exportMarkdown,
                  child: const Text('Экспорт Markdown'),
                ),
                ElevatedButton(
                  onPressed: _exportPdf,
                  child: const Text('Экспорт PDF'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionButton('Push'),
                _actionButton('Fold'),
                _actionButton('Call'),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedAction != null)
              Text(
                'Вы выбрали: $_selectedAction. GTO рекомендует: ${gto ?? '-'}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
  }

  Widget _actionButton(String label) {
    final bool isSelected = _selectedAction == label;
    return ElevatedButton(
      onPressed: () => setState(() => _selectedAction = label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blueGrey : Colors.black87,
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }
}
