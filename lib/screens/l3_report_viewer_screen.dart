import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/l3_cli_runner.dart';
import 'l3_ab_diff_screen.dart';

void _toast(BuildContext ctx, String msg, {Duration d = const Duration(seconds: 2)}) {
  final m = ScaffoldMessenger.of(ctx);
  m.clearSnackBars();
  m.showSnackBar(SnackBar(content: Text(msg), duration: d));
}

class L3ReportViewerScreen extends StatelessWidget {
  final String path;
  final String? logPath;
  final List<String> warnings;
  const L3ReportViewerScreen({
    super.key,
    required this.path,
    this.logPath,
    this.warnings = const [],
  });

  bool get _isDesktop =>
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

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
      appBar: AppBar(
        title: Text(loc.quickstartL3),
        actions: [
          IconButton(
            tooltip: loc.copyPath,
            icon: const Icon(Icons.copy),
            onPressed: () {
              if (_isDesktop) {
                Clipboard.setData(ClipboardData(text: path));
                _toast(context, loc.copied);
              } else {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    content: Text(loc.desktopOnly),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(loc.ok),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          if (logPath != null)
            IconButton(
              tooltip: loc.logs,
              icon: const Icon(Icons.article),
              onPressed: () async {
                if (_isDesktop) {
                  final navigator = Navigator.of(context);
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );
                  String? text;
                  Object? error;
                  try {
                    text = await File(logPath!).readAsString();
                  } catch (e) {
                    error = e;
                  } finally {
                    if (navigator.mounted) navigator.pop();
                  }
                  if (!context.mounted) return;
                  await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(loc.viewLogs),
                      content: error == null
                          ? SingleChildScrollView(
                              child: SelectableText(text!),
                            )
                          : SelectableText(error.toString()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(loc.ok),
                        ),
                      ],
                    ),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      content: Text(loc.desktopOnly),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(loc.ok),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          IconButton(
            tooltip: loc.folder,
            icon: const Icon(Icons.folder),
            onPressed: () {
              if (_isDesktop) {
                L3CliRunner.revealInFolder(path);
              } else {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    content: Text(loc.desktopOnly),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(loc.ok),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          IconButton(
            tooltip: loc.abDiff,
            icon: const Icon(Icons.compare_arrows),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const L3AbDiffScreen()),
              );
            },
          ),
        ],
      ),
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
              if (warnings.isNotEmpty)
                Container(
                  width: double.infinity,
                  color: Colors.amber[100],
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: warnings.map((w) => Text(w)).toList(),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(child: SelectableText(text)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: null, child: Text(loc.export)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
