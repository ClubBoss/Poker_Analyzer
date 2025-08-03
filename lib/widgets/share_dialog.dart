import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/snackbar_util.dart';

class ShareDialog extends StatelessWidget {
  final String text;
  const ShareDialog({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Share Spot'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: SelectableText(text, style: const TextStyle(color: Colors.white)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: text));
            Navigator.pop(context);
            SnackbarUtil.showMessage(context, 'Copied to clipboard');
          },
          child: const Text('Copy'),
        ),
        TextButton(
          onPressed: () => Share.share(text),
          child: const Text('Share'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

Future<void> showShareDialog(BuildContext context, String text) {
  return showDialog(
    context: context,
    builder: (_) => ShareDialog(text: text),
  );
}
