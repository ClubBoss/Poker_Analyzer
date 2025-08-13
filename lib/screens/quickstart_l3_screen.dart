import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../services/l3_cli_runner.dart';
import '../utils/shared_prefs_keys.dart';
import '../models/l3_run_history_entry.dart';
import 'l3_report_viewer_screen.dart';

class QuickstartL3Screen extends StatefulWidget {
  const QuickstartL3Screen({super.key});

  @override
  State<QuickstartL3Screen> createState() => _QuickstartL3ScreenState();
}

class _QuickstartL3ScreenState extends State<QuickstartL3Screen> {
  final _weightsController = TextEditingController();
  String? _weightsPreset;
  bool _running = false;
  L3CliResult? _result;
  String? _lastReportPath;
  String? _inlineWarning;
  String? _error;
  List<L3RunHistoryEntry> _history = [];
  final _historyService = L3RunHistoryService();

  bool get _isDesktop =>
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  @override
  void initState() {
    super.initState();
    _loadLast();
    if (!_isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final loc = AppLocalizations.of(context);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            content: Text(loc.desktopOnly),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        ).then((_) => Navigator.pop(context));
      });
    }
  }

  Future<void> _loadLast() async {
    final prefs = await SharedPreferences.getInstance();
    final hist = await _historyService.load();
    setState(() {
      _lastReportPath = prefs.getString(SharedPrefsKeys.lastL3ReportPath);
      _history = hist;
    });
  }

  Future<void> _run() async {
    setState(() {
      _running = true;
      _error = null;
      _inlineWarning = null;
    });
    var weights = _weightsController.text.trim();
    String? weightsArg = weights.isEmpty ? null : weights;
    var preset = _weightsPreset;
    if (weightsArg != null && preset != null) {
      weightsArg = null;
      _inlineWarning = AppLocalizations.of(context).presetWillBeUsed;
    }
    final runner = L3CliRunner();
    final res = await runner.run(weights: weightsArg, weightsPreset: preset);
    final prefs = await SharedPreferences.getInstance();
    final collectedWarnings = <String>[];
    if (_inlineWarning != null) collectedWarnings.add(_inlineWarning!);
    collectedWarnings.addAll(res.warnings);
    if (res.exitCode == 0) {
      await prefs.setString(SharedPrefsKeys.lastL3ReportPath, res.outPath);
      _lastReportPath = res.outPath;
      final entry = L3RunHistoryEntry(
        timestamp: DateTime.now(),
        argsSummary: preset != null
            ? 'preset=$preset'
            : (weightsArg != null ? 'weights=json' : 'default'),
        outPath: res.outPath,
        logPath: res.logPath,
        warnings: collectedWarnings,
        weights: weightsArg,
        preset: preset,
      );
      if (_history.isEmpty || !_history.first.sameAs(entry)) {
        await _historyService.push(entry);
        _history = await _historyService.load();
      }
    }
    setState(() {
      _running = false;
      _result = res;
      if (res.exitCode != 0) {
        _error = res.stderr;
      }
    });
    if (collectedWarnings.isNotEmpty && mounted) {
      for (final w in collectedWarnings) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(w)));
      }
    }
  }

  Future<void> _openReport() async {
    final path = _lastReportPath;
    if (path == null) return;
    L3RunHistoryEntry? entry;
    for (final e in _history) {
      if (e.outPath == path) {
        entry = e;
        break;
      }
    }
    final file = File(path);
    final exists = await file.exists();
    if (!exists || (await file.readAsString()).trim().isEmpty) {
      if (mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(loc.reportEmpty)));
      }
      return;
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => L3ReportViewerScreen(
          path: path,
          logPath: entry?.logPath,
          warnings: entry?.warnings ?? const [],
        ),
      ),
    );
  }

  void _viewLogs() {
    final path = _result?.logPath;
    if (path == null) return;
    _viewLogsFile(path);
  }

  void _viewLogsFile(String path) {
    final text = File(path).readAsStringSync();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context).viewLogs),
        content: SingleChildScrollView(child: SelectableText(text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openEntry(L3RunHistoryEntry e) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => L3ReportViewerScreen(
          path: e.outPath,
          logPath: e.logPath,
          warnings: e.warnings,
        ),
      ),
    );
  }

  void _openFolder(L3RunHistoryEntry e) {
    L3CliRunner.revealInFolder(e.outPath);
  }

  void _reRun(L3RunHistoryEntry e) {
    _weightsController.text = e.weights ?? '';
    setState(() => _weightsPreset = e.preset);
    _run();
  }

  Future<void> _clearHistory() async {
    final loc = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(loc.confirmClear),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.clear),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _historyService.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(SharedPrefsKeys.lastL3ReportPath);
      setState(() {
        _history = [];
        _lastReportPath = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.deleted)));
      }
    }
  }

  void _retry() {
    _run();
  }

  @override
  void dispose() {
    _weightsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    Widget body;
    if (_running) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: _viewLogs, child: Text(loc.viewLogs)),
                    TextButton(onPressed: _retry, child: Text(loc.retry)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      body = Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _weightsController,
              decoration: InputDecoration(labelText: loc.weightsJson),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              hint: Text(loc.weightsPreset),
              value: _weightsPreset,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'default', child: Text('default')),
                DropdownMenuItem(value: 'aggro', child: Text('aggro')),
                DropdownMenuItem(value: 'nitty', child: Text('nitty')),
              ],
              onChanged: (v) => setState(() => _weightsPreset = v),
            ),
            if (_weightsController.text.isNotEmpty && _weightsPreset != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_inlineWarning ?? ''),
              ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _run, child: Text(loc.run)),
            if (_lastReportPath != null)
              TextButton(onPressed: _openReport, child: Text(loc.openReport)),
            const SizedBox(height: 16),
            if (_history.isNotEmpty)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.recentRuns),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final e = _history[index];
                          final ts = DateFormat(
                            'yyyy-MM-dd HH:mm',
                          ).format(e.timestamp);
                          return Dismissible(
                            key: ValueKey('${e.outPath}${e.argsSummary}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) async {
                              setState(() => _history.removeAt(index));
                              await _historyService.save(_history);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(loc.deleted)),
                                );
                              }
                            },
                            child: ListTile(
                              title: Text('$ts ${e.argsSummary}'),
                              trailing: Wrap(
                                spacing: 4,
                                children: [
                                  TextButton(
                                    onPressed: () => _openEntry(e),
                                    child: Text(loc.open),
                                  ),
                                  TextButton(
                                    onPressed: () => _viewLogsFile(e.logPath),
                                    child: Text(loc.logs),
                                  ),
                                  if (_isDesktop)
                                    TextButton(
                                      onPressed: () => _openFolder(e),
                                      child: Text(loc.folder),
                                    ),
                                  TextButton(
                                    onPressed:
                                        _running ? null : () => _reRun(e),
                                    child: Text(loc.reRun),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.quickstartL3),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              tooltip: loc.clearHistory,
              onPressed: _clearHistory,
              icon: const Icon(Icons.delete_forever),
            ),
        ],
      ),
      body: body,
    );
  }
}
