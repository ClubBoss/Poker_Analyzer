import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show compute, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../services/l3_cli_runner.dart';
import '../utils/shared_prefs_keys.dart';
import '../models/l3_run_history_entry.dart';
import '../utils/toast.dart';
import '../utils/csv_io.dart';
import '../utils/history_csv.dart';
import '../utils/report_csv.dart';
import '../utils/temp_cleanup.dart';
import 'l3_report_viewer_screen.dart';

class QuickstartL3Screen extends StatefulWidget {
  const QuickstartL3Screen({super.key});

  @override
  State<QuickstartL3Screen> createState() => _QuickstartL3ScreenState();
}

class _RunIntent extends Intent {
  const _RunIntent();
}

class _ExportLastIntent extends Intent {
  const _ExportLastIntent();
}

class _ExportHistoryIntent extends Intent {
  const _ExportHistoryIntent();
}

class _OpenLastReportIntent extends Intent {
  const _OpenLastReportIntent();
}

class _OpenLastLogsIntent extends Intent {
  const _OpenLastLogsIntent();
}

class _RevealLastIntent extends Intent {
  const _RevealLastIntent();
}

class _CopyLastPathIntent extends Intent {
  const _CopyLastPathIntent();
}

class _CopyLastLogPathIntent extends Intent {
  const _CopyLastLogPathIntent();
}

class _QuickstartL3ScreenState extends State<QuickstartL3Screen> {
  final _weightsController = TextEditingController();
  String? _weightsPreset;
  String? _weightsJsonError;
  Timer? _weightsDebounce;
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
                child: Text(AppLocalizations.of(context).ok),
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
    var preset = prefs.getString(SharedPrefsKeys.l3WeightsPreset);
    var weightsJson = prefs.getString(SharedPrefsKeys.l3WeightsJson);
    if (preset != null && preset.isEmpty) {
      await prefs.remove(SharedPrefsKeys.l3WeightsPreset);
      preset = null;
    }
    if (weightsJson != null && weightsJson.isEmpty) {
      await prefs.remove(SharedPrefsKeys.l3WeightsJson);
      weightsJson = null;
    }
    setState(() {
      _lastReportPath = prefs.getString(SharedPrefsKeys.lastL3ReportPath);
      _weightsPreset = preset;
      _history = hist;
    });
    if (weightsJson != null) {
      _weightsController.text = weightsJson;
    }
  }

  Future<void> _formatWeightsJson() async {
    _weightsDebounce?.cancel();
    final text = _weightsController.text.trim();
    if (text.isEmpty) return;
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) return;
      final formatted = const JsonEncoder.withIndent('  ').convert(decoded);
      if (formatted != text) {
        _weightsController.text = formatted;
        _weightsController.selection = TextSelection.fromPosition(
          TextPosition(offset: formatted.length),
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(SharedPrefsKeys.l3WeightsJson, formatted);
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _run() async {
    await _formatWeightsJson();
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _running = true;
      _error = null;
      _inlineWarning = null;
    });
    var weights = _weightsController.text.trim();
    String? weightsArg = weights.isEmpty ? null : weights;
    var preset = _weightsPreset;
    if (weightsArg != null) {
      try {
        final decoded = jsonDecode(weightsArg);
        if (decoded is! Map) throw const FormatException();
      } catch (_) {
        if (mounted) {
          showToast(context, AppLocalizations.of(context).invalidJson);
        }
        setState(() {
          _running = false;
        });
        return;
      }
    }
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
      final current = await _historyService.load();
      if (current.isEmpty || !current.first.sameAs(entry)) {
        await _historyService.push(entry);
        _history = await _historyService.load();
      } else {
        _history = current;
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
      messenger.clearSnackBars();
      for (final w in collectedWarnings) {
        messenger.showSnackBar(
          SnackBar(content: Text(w), duration: const Duration(seconds: 2)),
        );
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
        showToast(context, loc.reportEmpty);
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

  Future<void> _openLastLogs() async {
    final path = _lastReportPath;
    if (path == null) return;
    L3RunHistoryEntry? entry;
    for (final e in _history) {
      if (e.outPath == path) {
        entry = e;
        break;
      }
    }
    final logPath = entry?.logPath;
    if (logPath == null) return;
    await _viewLogsFile(logPath);
  }

  Future<void> _exportLastCsv() async {
    final loc = AppLocalizations.of(context);
    final path = _lastReportPath;
    if (path == null) {
      showToast(context, loc.reportEmpty);
      return;
    }
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
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final csv = await compute(buildReportCsv, content);
    if (navigator.mounted) navigator.pop();
    if (csv == null) {
      showToast(context, loc.invalidJson);
      return;
    }
    await cleanupOldTempDirs(prefix: 'l3_report_');
    final dir = await Directory(
      '${Directory.systemTemp.path}/l3_report_${DateTime.now().millisecondsSinceEpoch}',
    ).create(recursive: true);
    final out = File('${dir.path}/report.csv');
    await writeCsv(out, StringBuffer()..write(csv));
    if (!_isDesktop) HapticFeedback.selectionClick();
    if (!mounted) return;
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
                if (!_isDesktop) HapticFeedback.selectionClick();
                messenger.clearSnackBars();
                showToast(context, loc.copied);
              },
              child: Text(loc.copyPath),
            ),
            if (!_isDesktop)
              TextButton(
                onPressed: () async {
                  final text = await out.readAsString();
                  if (!mounted) return;
                  messenger.clearSnackBars();
                  await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      content: SingleChildScrollView(
                        child: SelectableText(text),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(loc.ok),
                        ),
                      ],
                    ),
                  );
                },
                child: Text(loc.open),
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
  }

  Future<void> _exportHistoryCsv() async {
    final loc = AppLocalizations.of(context);
    if (_history.isEmpty) {
      showToast(context, loc.reportEmpty);
      return;
    }
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final payload = _history
        .map(
          (e) => {
            'ts': e.timestamp.toIso8601String(),
            'args': e.argsSummary,
            'out': e.outPath,
            'log': e.logPath,
          },
        )
        .toList();
    final csv = await compute(buildHistoryCsv, payload);
    if (navigator.mounted) navigator.pop();
    await cleanupOldTempDirs(prefix: 'l3_history_');
    final dir = await Directory(
      '${Directory.systemTemp.path}/l3_history_${DateTime.now().millisecondsSinceEpoch}',
    ).create(recursive: true);
    final out = File('${dir.path}/history.csv');
    await writeCsv(out, StringBuffer()..write(csv));
    if (!_isDesktop) HapticFeedback.selectionClick();
    if (!mounted) return;
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
                if (!_isDesktop) HapticFeedback.selectionClick();
                messenger.clearSnackBars();
                showToast(context, loc.copied);
              },
              child: Text(loc.copyPath),
            ),
            if (!_isDesktop)
              TextButton(
                onPressed: () async {
                  final text = await out.readAsString();
                  if (!mounted) return;
                  messenger.clearSnackBars();
                  await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      content: SingleChildScrollView(
                        child: SelectableText(text),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(loc.ok),
                        ),
                      ],
                    ),
                  );
                },
                child: Text(loc.open),
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
  }

  Future<void> _viewLogs() async {
    final path = _result?.logPath;
    if (path == null) return;
    await _viewLogsFile(path);
  }

  Future<void> _viewLogsFile(String path) async {
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    String? text;
    Object? error;
    try {
      text = await File(path).readAsString();
    } catch (e) {
      error = e;
    } finally {
      if (navigator.mounted) navigator.pop();
    }
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context).viewLogs),
        content: error == null
            ? SingleChildScrollView(child: SelectableText(text!))
            : SelectableText(error.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).ok),
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
        showToast(context, loc.deleted);
      }
    }
  }

  void _retry() {
    _run();
  }

  @override
  void dispose() {
    _weightsDebounce?.cancel();
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
                    TextButton(
                      onPressed: () async {
                        await _viewLogs();
                      },
                      child: Text(loc.viewLogs),
                    ),
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
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                labelText: loc.weightsJson,
                errorText: _weightsJsonError,
                suffixIcon: _weightsController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () async {
                          _weightsDebounce?.cancel();
                          _weightsController.clear();
                          _weightsJsonError = null;
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove(SharedPrefsKeys.l3WeightsJson);
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
              ),
              onTapOutside: (_) => _formatWeightsJson(),
              onEditingComplete: () => _formatWeightsJson(),
              onChanged: (_) {
                _weightsDebounce?.cancel();
                _weightsDebounce = Timer(
                  const Duration(milliseconds: 250),
                  () async {
                    final text = _weightsController.text.trim();
                    String? error;
                    try {
                      if (text.isNotEmpty) {
                        final decoded = jsonDecode(text);
                        if (decoded is! Map) throw const FormatException();
                      }
                    } catch (_) {
                      error = loc.invalidJson;
                    }
                    final prefs = await SharedPreferences.getInstance();
                    if (text.isEmpty) {
                      await prefs.remove(SharedPrefsKeys.l3WeightsJson);
                    } else {
                      await prefs.setString(
                        SharedPrefsKeys.l3WeightsJson,
                        text,
                      );
                    }
                    if (!mounted) return;
                    setState(() {
                      _weightsJsonError = error;
                    });
                  },
                );
              },
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
              onChanged: (v) async {
                final prefs = await SharedPreferences.getInstance();
                if (v == null || v.isEmpty) {
                  setState(() => _weightsPreset = null);
                  await prefs.remove(SharedPrefsKeys.l3WeightsPreset);
                } else {
                  setState(() => _weightsPreset = v);
                  await prefs.setString(SharedPrefsKeys.l3WeightsPreset, v);
                }
              },
            ),
            if (_weightsController.text.trim().isNotEmpty &&
                (_weightsPreset?.isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(loc.presetWillBeUsed),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: (_running || _weightsJsonError != null) ? null : _run,
              child: Text(loc.run),
            ),
            if (_lastReportPath != null)
              Row(
                children: [
                  TextButton(
                    onPressed: _openReport,
                    child: Text(loc.openReport),
                  ),
                  TextButton(
                    onPressed: _exportLastCsv,
                    child: Text(loc.exportCsv),
                  ),
                  TextButton(
                    onPressed: () {
                      if (_lastReportPath == null) return;
                      Clipboard.setData(ClipboardData(text: _lastReportPath!));
                      showToast(context, loc.copied);
                    },
                    child: Text(loc.copyPath),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            if (_history.isNotEmpty)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(loc.recentRuns)),
                        TextButton(
                          onPressed: _exportHistoryCsv,
                          child: Text(loc.exportCsv),
                        ),
                      ],
                    ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (_) async {
                              final removed = _history.removeAt(index);
                              await _historyService.save(_history);
                              final prefs =
                                  await SharedPreferences.getInstance();
                              if (_lastReportPath == removed.outPath) {
                                if (_history.isNotEmpty) {
                                  final newPath = _history.first.outPath;
                                  await prefs.setString(
                                    SharedPrefsKeys.lastL3ReportPath,
                                    newPath,
                                  );
                                  _lastReportPath = newPath;
                                } else {
                                  await prefs.remove(
                                    SharedPrefsKeys.lastL3ReportPath,
                                  );
                                  _lastReportPath = null;
                                }
                              }
                              setState(() {});
                              if (mounted) {
                                showToast(context, loc.deleted);
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
                                    onPressed: () async {
                                      await _viewLogsFile(e.logPath);
                                    },
                                    child: Text(loc.logs),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(text: e.outPath),
                                      );
                                      HapticFeedback.selectionClick();
                                      showToast(context, loc.copied);
                                    },
                                    child: Text(loc.copyPath),
                                  ),
                                  if (_isDesktop)
                                    TextButton(
                                      onPressed: () => _openFolder(e),
                                      child: Text(loc.folder),
                                    ),
                                  TextButton(
                                    onPressed: _running
                                        ? null
                                        : () => _reRun(e),
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
    body = Shortcuts(
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true):
            const _RunIntent(),
        const SingleActivator(LogicalKeyboardKey.enter, meta: true):
            const _RunIntent(),
        // Copy last report path
        const SingleActivator(LogicalKeyboardKey.keyC, control: true):
            const _CopyLastPathIntent(),
        const SingleActivator(LogicalKeyboardKey.keyC, meta: true):
            const _CopyLastPathIntent(),
        // Copy last logs path (Shift)
        const SingleActivator(
          LogicalKeyboardKey.keyC,
          control: true,
          shift: true,
        ): const _CopyLastLogPathIntent(),
        const SingleActivator(LogicalKeyboardKey.keyC, meta: true, shift: true):
            const _CopyLastLogPathIntent(),
        // Export last report CSV
        const SingleActivator(LogicalKeyboardKey.keyE, control: true):
            const _ExportLastIntent(),
        const SingleActivator(LogicalKeyboardKey.keyE, meta: true):
            const _ExportLastIntent(),
        // Export history CSV (Shift)
        const SingleActivator(
          LogicalKeyboardKey.keyE,
          control: true,
          shift: true,
        ): const _ExportHistoryIntent(),
        const SingleActivator(LogicalKeyboardKey.keyE, meta: true, shift: true):
            const _ExportHistoryIntent(),
        // Open last report
        const SingleActivator(LogicalKeyboardKey.keyO, control: true):
            const _OpenLastReportIntent(),
        const SingleActivator(LogicalKeyboardKey.keyO, meta: true):
            const _OpenLastReportIntent(),
        // Open last logs
        const SingleActivator(LogicalKeyboardKey.keyL, control: true):
            const _OpenLastLogsIntent(),
        const SingleActivator(LogicalKeyboardKey.keyL, meta: true):
            const _OpenLastLogsIntent(),
        // Reveal last report in folder
        const SingleActivator(
          LogicalKeyboardKey.keyR,
          control: true,
          shift: true,
        ): const _RevealLastIntent(),
        const SingleActivator(LogicalKeyboardKey.keyR, meta: true, shift: true):
            const _RevealLastIntent(),
      },
      child: Actions(
        actions: {
          _RunIntent: CallbackAction<_RunIntent>(
            onInvoke: (intent) {
              if (!(_isDesktop && !_running && _weightsJsonError == null)) {
                return null;
              }
              _run();
              return null;
            },
          ),
          _CopyLastPathIntent: CallbackAction<_CopyLastPathIntent>(
            onInvoke: (_) {
              if (!(_isDesktop && _lastReportPath != null)) return null;
              Clipboard.setData(ClipboardData(text: _lastReportPath!));
              showToast(context, AppLocalizations.of(context).copied);
              return null;
            },
          ),
          _CopyLastLogPathIntent: CallbackAction<_CopyLastLogPathIntent>(
            onInvoke: (_) {
              if (!_isDesktop || _lastReportPath == null) return null;
              final entry = _history.firstWhere(
                (e) => e.outPath == _lastReportPath,
                orElse: () => null as dynamic,
              );
              final log = (entry as L3RunHistoryEntry?)?.logPath;
              if (log == null) return null;
              Clipboard.setData(ClipboardData(text: log));
              showToast(context, AppLocalizations.of(context).copied);
              return null;
            },
          ),
          _ExportLastIntent: CallbackAction<_ExportLastIntent>(
            onInvoke: (_) {
              if (!(_isDesktop && _lastReportPath != null)) return null;
              _exportLastCsv();
              return null;
            },
          ),
          _ExportHistoryIntent: CallbackAction<_ExportHistoryIntent>(
            onInvoke: (_) {
              if (!(_isDesktop && _history.isNotEmpty)) return null;
              _exportHistoryCsv();
              return null;
            },
          ),
          _OpenLastReportIntent: CallbackAction<_OpenLastReportIntent>(
            onInvoke: (_) {
              if (!(_isDesktop && _lastReportPath != null)) return null;
              _openReport();
              return null;
            },
          ),
          _OpenLastLogsIntent: CallbackAction<_OpenLastLogsIntent>(
            onInvoke: (_) {
              if (!(_isDesktop && _lastReportPath != null)) return null;
              _openLastLogs();
              return null;
            },
          ),
          _RevealLastIntent: CallbackAction<_RevealLastIntent>(
            onInvoke: (_) {
              if (!(_isDesktop && _lastReportPath != null)) return null;
              L3CliRunner.revealInFolder(_lastReportPath!);
              return null;
            },
          ),
        },
        child: body,
      ),
    );
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
