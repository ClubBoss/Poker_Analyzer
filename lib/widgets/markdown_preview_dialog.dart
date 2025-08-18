import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/v2/training_pack_template.dart';
import '../services/pack_export_service.dart';

class MarkdownPreviewDialog extends StatelessWidget {
  final String? markdown;
  final TrainingPackTemplate? template;
  const MarkdownPreviewDialog({super.key, this.markdown, this.template});

  @override
  Widget build(BuildContext context) {
    final md = markdown ?? PackExportService.toMarkdown(template!);
    return AlertDialog(
      title: const Text('Markdown Preview'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: SelectableText(
            md,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: md));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Copied')));
          },
          child: const Text('Copy'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Save'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

Future<bool?> showMarkdownPreviewDialog(BuildContext context, String markdown) {
  return showDialog<bool>(
    context: context,
    builder: (_) => MarkdownPreviewDialog(markdown: markdown),
  );
}
