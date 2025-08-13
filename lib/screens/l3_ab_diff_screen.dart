import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/l3_run_history_entry.dart';
import '../services/l3_cli_runner.dart';
import '../utils/toast.dart';
import '../utils/csv_io.dart';

String buildAbCsv(Map<String, dynamic> payload) {
  final Map<String, num> a = (payload['a'] as Map).cast<String, num>();
  final Map<String, num> b = (payload['b'] as Map).cast<String, num>();
  final String argsA = payload['argsA'] as String? ?? '-';
  final String argsB = payload['argsB'] as String? ?? '-';
  String _csv(String v) => '"${v.replaceAll('"', '""')}"';

  final keys = <String>{...a.keys, ...b.keys}.toList()..sort();
  final buffer = StringBuffer()
    ..writeln('metric,a,b,delta')
    ..writeln('${_csv('args')},${_csv(argsA)},${_csv(argsB)},');
  for (final k in keys) {
    final av = a[k];
    final bv = b[k];
    final delta = (bv ?? 0) - (av ?? 0);
    buffer.writeln('${_csv(k)},$av,$bv,$delta');
  }
  return buffer.toString();
}

class _ExportIntent extends Intent {
  const _ExportIntent();
}

class L3AbDiffScreen extends StatefulWidget {
  const L3AbDiffScreen({super.key});

  @override
  State<L3AbDiffScreen> createState() => _L3AbDiffScreenState();
}

class _L3AbDiffScreenState extends State<L3AbDiffScreen> {
  final _historyService = L3RunHistoryService();
  List<L3RunHistoryEntry> _history = [];
  L3RunHistoryEntry? _a;
  L3RunHistoryEntry? _b;
  Map<String, num>? _statsA;
  Map<String, num>? _statsB;

  bool get _isDesktop =>
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final h = await _historyService.load();
    setState(() => _history = h);
  }

  Future<Map<String, num>> _stats(String path) async {
    final file = File(path);
    if (!await file.exists()) return {};
    final content = await file.readAsString();
    final decoded = jsonDecode(content);
    final result = <String, num>{};
    if (decoded is Map) {
      result['rootKeys'] = decoded.length;
      decoded.forEach((key, value) {
        if (value is num) {
          result[key] = value;
        } else if (value is List) {
          result['array:$key'] = value.length;
        }
      });
    }
    return result;
  }

  Future<void> _compare() async {
    final a = _a;
    final b = _b;
    if (a == null || b == null) return;
    final statsA = await _stats(a.outPath);
    final statsB = await _stats(b.outPath);
    setState(() {
      _statsA = statsA;
      _statsB = statsB;
    });
  }

  String _f(num? v, {bool signed = false}) {
    if (v == null) return '-';
    final fmt = NumberFormat(
      signed ? '+#,##0.####;-#,##0.####;0' : '#,##0.####',
    );
    return fmt.format(v);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    Widget body = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.pickTwoRuns),
          Expanded(
            child: ListView.builder(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final e = _history[index];
                final ts = DateFormat('yyyy-MM-dd HH:mm').format(e.timestamp);
                final selected = e == _a || e == _b;
                return ListTile(
                  selected: selected,
                  onTap: () {
                    setState(() {
                      if (_a == e) {
                        _a = null;
                      } else if (_b == e) {
                        _b = null;
                      } else if (_a == null) {
                        _a = e;
                      } else if (_b == null) {
                        _b = e;
                      } else {
                        _a = e;
                        _b = null;
                      }
                    });
                  },
                  title: Text('$ts ${e.argsSummary}'),
                  leading: Checkbox(
                    value: selected,
                    onChanged: (_) {
                      setState(() {
                        if (selected) {
                          if (_a == e) {
                            _a = null;
                          } else {
                            _b = null;
                          }
                        } else if (_a == null) {
                          _a = e;
                        } else if (_b == null) {
                          _b = e;
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: _a != null && _b != null ? _compare : null,
                child: Text(loc.compare),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _statsA != null && _statsB != null
                    ? _exportCsv
                    : null,
                child: Text(loc.exportCsv),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_statsA != null && _statsB != null)
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: [
                    const DataColumn(label: Text('')),
                    DataColumn(label: Text('A')),
                    DataColumn(label: Text('B')),
                    DataColumn(label: Text(loc.delta)),
                  ],
                  rows: _buildRows(loc),
                ),
              ),
            )
          else
            Text(loc.noSelection),
        ],
      ),
    );
    body = Shortcuts(
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.keyE, control: true):
            const _ExportIntent(),
        const SingleActivator(LogicalKeyboardKey.keyE, meta: true):
            const _ExportIntent(),
      },
      child: Actions(
        actions: {
          _ExportIntent: CallbackAction<_ExportIntent>(
            onInvoke: (intent) {
              if (!(_isDesktop && mounted)) return null;
              _exportCsv();
              return null;
            },
          ),
        },
        child: body,
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(loc.abDiff)),
      body: body,
    );
  }

  List<DataRow> _buildRows(AppLocalizations loc) {
    final keys = <String>{...?_statsA?.keys, ...?_statsB?.keys}.toList()
      ..sort();
    final rows = <DataRow>[
      DataRow(
        cells: [
          DataCell(Text(loc.args)),
          DataCell(Text(_a?.argsSummary ?? '-')),
          DataCell(Text(_b?.argsSummary ?? '-')),
          const DataCell(Text('-')),
        ],
      ),
    ];
    for (final k in keys) {
      final a = _statsA?[k];
      final b = _statsB?[k];
      final delta = b != null && a != null ? b - a : null;
      final label = k == 'rootKeys'
          ? loc.rootKeys
          : k.startsWith('array:')
          ? '${loc.arrayLengths} ${k.substring(6)}'
          : k;
      rows.add(
        DataRow(
          cells: [
            DataCell(Text(label)),
            DataCell(Text(_f(a))),
            DataCell(Text(_f(b))),
            DataCell(Text(_f(delta, signed: true))),
          ],
        ),
      );
    }
    return rows;
  }

  Future<void> _exportCsv() async {
    final statsA = _statsA;
    final statsB = _statsB;
    if (statsA == null || statsB == null) return;
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final payload = {
      'a': statsA,
      'b': statsB,
      'argsA': _a?.argsSummary,
      'argsB': _b?.argsSummary,
    };
    final csv = await compute(buildAbCsv, payload);
    if (navigator.mounted) navigator.pop();
    final dir = await Directory.systemTemp.createTemp('l3_ab');
    final file = File('${dir.path}/ab_diff.csv');
    await writeCsv(file, StringBuffer()..write(csv));
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
                Clipboard.setData(ClipboardData(text: file.path));
                if (!_isDesktop) HapticFeedback.selectionClick();
                messenger.clearSnackBars();
                showToast(context, loc.copied);
              },
              child: Text(loc.copyPath),
            ),
            if (!_isDesktop)
              TextButton(
                onPressed: () async {
                  final text = await file.readAsString();
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
                onPressed: () => L3CliRunner.revealInFolder(file.path),
                child: Text(loc.reveal),
              ),
          ],
        ),
      ),
    );
  }
}
