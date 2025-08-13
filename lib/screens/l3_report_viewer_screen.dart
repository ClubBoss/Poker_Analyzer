import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class L3ReportViewerScreen extends StatelessWidget {
  final String path;
  const L3ReportViewerScreen({super.key, required this.path});

  Future<String> _load() async {
    final file = File(path);
    if (!await file.exists()) return '';
    final content = await file.readAsString();
    try {
      final decoded = jsonDecode(content);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return content;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.quickstartL3)),
      body: FutureBuilder<String>(
        future: _load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final text = snapshot.data ?? '';
          if (text.isEmpty) {
            return Center(child: Text(loc.reportEmpty));
          }
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(text),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: null, child: Text(loc.abDiff)),
                  TextButton(onPressed: null, child: Text(loc.export)),
                ],
              )
            ],
          );
        },
      ),
    );
  }
}
