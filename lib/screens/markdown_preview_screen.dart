import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:markdown/markdown.dart' as md;

class MarkdownPreviewScreen extends StatefulWidget {
  final String path;

  const MarkdownPreviewScreen({super.key, required this.path});

  @override
  State<MarkdownPreviewScreen> createState() => _MarkdownPreviewScreenState();
}

class _MarkdownPreviewScreenState extends State<MarkdownPreviewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    _loadContent();
  }

  Future<void> _loadContent() async {
    final file = File(widget.path);
    final markdown = await file.readAsString();
    final html = _wrapHtml(md.markdownToHtml(markdown));
    if (mounted) {
      await _controller.loadHtmlString(html);
    }
  }

  String _wrapHtml(String body) {
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
body { font-family: sans-serif; padding: 16px; }
</style>
</head>
<body>$body</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Markdown Preview'),
        centerTitle: true,
      ),
      body: WebViewWidget(controller: _controller),
      backgroundColor: const Color(0xFF1B1C1E),
    );
  }
}
