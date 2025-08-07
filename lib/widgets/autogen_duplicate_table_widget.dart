import 'package:flutter/material.dart';

import '../services/autogen_status_dashboard_service.dart';

class AutogenDuplicateTableWidget extends StatelessWidget {
  const AutogenDuplicateTableWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AutogenStatusDashboardService.instance;
    return ValueListenableBuilder<List<DuplicatePackInfo>>(
      valueListenable: service.duplicatesNotifier,
      builder: (context, duplicates, _) {
        if (duplicates.isEmpty) {
          return const Center(child: Text('No duplicates'));
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Candidate')),
              DataColumn(label: Text('Existing')),
              DataColumn(label: Text('Similarity %')),
              DataColumn(label: Text('Reason')),
            ],
            rows: [
              for (final d in duplicates)
                DataRow(cells: [
                  DataCell(Text(d.candidateId)),
                  DataCell(Text(d.existingId)),
                  DataCell(Text('${(d.similarity * 100).toStringAsFixed(1)}')),
                  DataCell(Text(d.reason)),
                ]),
            ],
          ),
        );
      },
    );
  }
}
