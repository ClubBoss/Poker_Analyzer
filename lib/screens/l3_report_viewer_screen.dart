import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/l3_cli_runner.dart';
import '../utils/toast.dart';
import 'l3_ab_diff_screen.dart';

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

  String _csv(String v) => '"${v.replaceAll('"', '""')}"';

  Future<void> _exportCsv(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    try {
      final file = File(path);
      if (!await file.exists()) {
        showToast(context, loc.reportEmpty);
        return;
      }
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        showToast(context, loc.reportEmpty);
        return;
      }
      dynamic decoded;
      try {
        decoded = jsonDecode(content);
      } catch (_) {
        showToast(context, loc.invalidJson);
        return;
      }
      if (decoded is! Map) {
        showToast(context, loc.invalidJson);
        return;
      }
      final buffer = StringBuffer()
        ..writeln('metric,value')
        ..writeln('${_csv('rootKeys')},${decoded.length}');
      final keys = decoded.keys.map((e) => e.toString()).toList()..sort();
      for (final k in keys) {
        final v = decoded[k];
        if (v is num) {
          buffer.writeln('${_csv(k)},$v');
        } else if (v is List) {
          buffer.writeln('${_csv('array:$k')},${v.length}');
        }
      }
      final dir = await Directory(
              '${Directory.systemTemp.path}/l3_report_${DateTime.now().millisecondsSinceEpoch}')
          .create(recursive: true);
      final out = File('${dir.path}/report.csv');
      await out.writeAsString(buffer.toString());
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Expanded(child: Text(loc.csvSaved)),
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: out.path));
                  showToast(context, loc.copied);
                },
                child: Text(loc.copyPath),
              ),
              if (_isDesktop)
                TextButton(
                  onPressed: () => L3CliRunner.revealInFolder(out.path),
                  child: Text(loc.reveal),
                ),
            ],
          ),
        ),
      );
    } catch (_) {}
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
                showToast(context, loc.copied);
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
                  TextButton(
                    onPressed: () => _exportCsv(context),
                    child: Text(loc.exportCsv),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
