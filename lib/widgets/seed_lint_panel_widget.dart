import 'dart:io';

import 'package:flutter/material.dart';

import '../core/models/spot_seed/seed_issue.dart';
import '../services/autogen_status_dashboard_service.dart';

/// Panel displaying validation issues for ingested seeds.
class SeedLintPanelWidget extends StatefulWidget {
  const SeedLintPanelWidget({super.key});

  @override
  State<SeedLintPanelWidget> createState() => _SeedLintPanelWidgetState();
}

class _SeedLintPanelWidgetState extends State<SeedLintPanelWidget> {
  String? _severityFilter;

  @override
  Widget build(BuildContext context) {
    final service = AutogenStatusDashboardService.instance;
    return ValueListenableBuilder<List<SeedIssue>>(
      valueListenable: service.seedIssuesNotifier,
      builder: (context, issues, _) {
        final filtered = _severityFilter == null
            ? issues
            : issues.where((i) => i.severity == _severityFilter).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Seed Lint'),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  hint: const Text('Severity'),
                  value: _severityFilter,
                  items: const [
                    DropdownMenuItem(value: 'warn', child: Text('Warn')),
                    DropdownMenuItem(value: 'error', child: Text('Error')),
                  ],
                  onChanged: (v) => setState(() => _severityFilter = v),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final rows = [
                      ['id', 'severity', 'code', 'message'],
                      ...issues.map((i) =>
                          [i.seedId ?? '', i.severity, i.code, i.message])
                    ];
                    final csv = rows.map((r) => r.join(',')).join('\n');
                    final file = File('seed_lint.csv');
                    await file.writeAsString(csv);
                  },
                  child: const Text('Download CSV'),
                )
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
                      DataRow(cells: [
                        DataCell(Text(i.seedId ?? '')),
                        DataCell(Text(i.severity)),
                        DataCell(Text(i.code)),
                        DataCell(Text(i.message)),
                      ])
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

