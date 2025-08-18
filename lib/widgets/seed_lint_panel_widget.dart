import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/models/spot_seed/seed_issue.dart';
import '../services/autogen_status_dashboard_service.dart';

/// Panel displaying validation issues for ingested seeds.
class SeedLintPanelWidget extends StatefulWidget {
  const SeedLintPanelWidget({super.key});

  @override
  State<SeedLintPanelWidget> createState() => _SeedLintPanelWidgetState();
}

class _SeedLintPanelWidgetState extends State<SeedLintPanelWidget> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final service = AutogenStatusDashboardService.instance;
    return ValueListenableBuilder<List<SeedIssue>>(
      valueListenable: service.seedIssuesNotifier,
      builder: (context, issues, _) {
        final filtered = _filter == 'all'
            ? issues
            : issues.where((i) => i.severity == _filter).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Seed Lint'),
                const SizedBox(width: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _filter == 'all',
                      onSelected: (_) => setState(() => _filter = 'all'),
                    ),
                    ChoiceChip(
                      label: const Text('Warn'),
                      selected: _filter == 'warn',
                      onSelected: (_) => setState(() => _filter = 'warn'),
                    ),
                    ChoiceChip(
                      label: const Text('Error'),
                      selected: _filter == 'error',
                      onSelected: (_) => setState(() => _filter = 'error'),
                    ),
                  ],
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final data = filtered
                        .map(
                          (i) => {
                            'seedId': i.seedId,
                            'severity': i.severity,
                            'code': i.code,
                            'message': i.message,
                            'path': i.path,
                          },
                        )
                        .toList();
                    await Clipboard.setData(
                      ClipboardData(text: jsonEncode(data)),
                    );
                  },
                  child: const Text('Copy JSON'),
                ),
                TextButton(
                  onPressed: () async {
                    final rows = [
                      ['id', 'severity', 'code', 'message'],
                      ...issues.map(
                        (i) => [i.seedId ?? '', i.severity, i.code, i.message],
                      ),
                    ];
                    final csv = rows.map((r) => r.join(',')).join('\n');
                    final file = File('seed_lint.csv');
                    await file.writeAsString(csv);
                  },
                  child: const Text('Download CSV'),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Seed ID')),
                    DataColumn(label: Text('Severity')),
                    DataColumn(label: Text('Code')),
                    DataColumn(label: Text('Message')),
                  ],
                  rows: [
                    for (final i in filtered)
                      DataRow(
                        cells: [
                          DataCell(Text(i.seedId ?? '')),
                          DataCell(Text(i.severity)),
                          DataCell(Text(i.code)),
                          DataCell(Text(i.message)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
