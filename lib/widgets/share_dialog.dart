import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class ShareDialog extends StatelessWidget {
  final String text;
  const ShareDialog({super.key, required this.text});

  Widget _dialogButton(String label, VoidCallback onPressed) {
    return TextButton(onPressed: onPressed, child: Text(label));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Share Spot'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: SelectableText(
            text,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
      actions: [
        _dialogButton('Copy', () {
          Clipboard.setData(ClipboardData(text: text));
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
        }),
        _dialogButton('Share', () => Share.share(text)),
        _dialogButton('Close', () => Navigator.pop(context)),
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
