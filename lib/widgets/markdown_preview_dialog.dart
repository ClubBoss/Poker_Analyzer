import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MarkdownPreviewDialog extends StatelessWidget {
  final String markdown;
  const MarkdownPreviewDialog({super.key, required this.markdown});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Markdown Preview'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: SelectableText(markdown, style: const TextStyle(color: Colors.white)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: markdown));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied')),
            );
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
