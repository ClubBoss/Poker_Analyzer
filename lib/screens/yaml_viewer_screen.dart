import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../utils/snackbar_util.dart';

class YamlViewerScreen extends StatelessWidget {
  final String yamlText;
  final String title;
  const YamlViewerScreen({super.key, required this.yamlText, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: yamlText));
              SnackbarUtil.showMessage(context, 'Copied');
            },
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: SelectableText(yamlText, style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
