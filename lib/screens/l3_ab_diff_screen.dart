import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/l3_run_history_entry.dart';

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
  Map<String, int>? _statsA;
  Map<String, int>? _statsB;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final h = await _historyService.load();
    setState(() => _history = h);
  }

  Future<Map<String, int>> _stats(String path) async {
    final file = File(path);
    if (!await file.exists()) return {};
    final content = await file.readAsString();
    final decoded = jsonDecode(content);
    final result = <String, int>{};
    if (decoded is Map) {
      result['rootKeys'] = decoded.length;
      decoded.forEach((key, value) {
        if (value is List) {
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.abDiff)),
      body: Padding(
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
                  final ts =
                      DateFormat('yyyy-MM-dd HH:mm').format(e.timestamp);
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
                ElevatedButton(onPressed: null, child: Text(loc.export)),
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
                    ],
                    rows: _buildRows(loc),
                  ),
                ),
              )
            else
              Text(loc.noSelection),
          ],
        ),
      ),
    );
  }

  List<DataRow> _buildRows(AppLocalizations loc) {
    final keys = <String>{...?_statsA?.keys, ...?_statsB?.keys};
    final rows = <DataRow>[];
    for (final k in keys) {
      String label;
      if (k == 'rootKeys') {
        label = loc.rootKeys;
      } else if (k.startsWith('array:')) {
        label = '${loc.arrayLengths} ${k.substring(6)}';
      } else {
        label = k;
      }
      rows.add(DataRow(cells: [
        DataCell(Text(label)),
        DataCell(Text(_statsA?[k]?.toString() ?? '-')),
        DataCell(Text(_statsB?[k]?.toString() ?? '-')),
      ]));
    }
    return rows;
  }
}

