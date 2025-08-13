import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../services/l3_cli_runner.dart';
import '../utils/shared_prefs_keys.dart';
import '../models/l3_run_history_entry.dart';
import '../utils/toast.dart';
import 'l3_report_viewer_screen.dart';

class QuickstartL3Screen extends StatefulWidget {
  const QuickstartL3Screen({super.key});

  @override
  State<QuickstartL3Screen> createState() => _QuickstartL3ScreenState();
}

class _RunIntent extends Intent {
  const _RunIntent();
}

class _QuickstartL3ScreenState extends State<QuickstartL3Screen> {
  final _weightsController = TextEditingController();
  String? _weightsPreset;
  String? _weightsJsonError;
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
          SnackBar(
            content: Text(w),
            duration: const Duration(seconds: 2),
          ),
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
                        child: Text(loc.viewLogs)),
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
              onChanged: (_) async {
                final text = _weightsController.text.trim();
                try {
                  if (text.isNotEmpty) {
                    final decoded = jsonDecode(text);
                    if (decoded is! Map) throw const FormatException();
                  }
                  _weightsJsonError = null;
                } catch (_) {
                  _weightsJsonError = loc.invalidJson;
                }
                setState(() {});
                final prefs = await SharedPreferences.getInstance();
                if (text.isEmpty) {
                  await prefs.remove(SharedPrefsKeys.l3WeightsJson);
                } else {
                  await prefs.setString(SharedPrefsKeys.l3WeightsJson, text);
                }
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
              onPressed:
                  (_running || _weightsJsonError != null) ? null : _run,
              child: Text(loc.run),
            ),
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
                                        SharedPrefsKeys.lastL3ReportPath);
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
                                          ClipboardData(text: e.outPath));
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
    body = Shortcuts(
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true):
            const _RunIntent(),
        const SingleActivator(LogicalKeyboardKey.enter, meta: true):
            const _RunIntent(),
      },
      child: Actions(
        actions: {
          _RunIntent: CallbackAction<_RunIntent>(onInvoke: (intent) {
            if (!(_isDesktop && !_running && _weightsJsonError == null)) {
              return null;
            }
            _run();
            return null;
          }),
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
