import 'package:flutter/material.dart';

import '../models/theory_gap.dart';
import '../services/theory_gap_detector.dart';

/// Dashboard panel displaying theory coverage gaps.
class TheoryCoveragePanelWidget extends StatefulWidget {
  const TheoryCoveragePanelWidget({super.key, TheoryGapDetector? detector})
    : detector = detector ?? TheoryGapDetector();

  final TheoryGapDetector detector;

  @override
  State<TheoryCoveragePanelWidget> createState() =>
      _TheoryCoveragePanelWidgetState();
}

class _TheoryCoveragePanelWidgetState extends State<TheoryCoveragePanelWidget> {
  @override
  void initState() {
    super.initState();
    widget.detector.detectGaps();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<TheoryGap>>(
      valueListenable: widget.detector.gapsNotifier,
      builder: (context, gaps, _) {
        if (gaps.isEmpty) {
          return const Center(child: Text('No theory gaps'));
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Topic')),
              DataColumn(label: Text('Coverage'), numeric: true),
              DataColumn(label: Text('Target'), numeric: true),
              DataColumn(label: Text('Candidates')),
              DataColumn(label: Text('Priority'), numeric: true),
            ],
            rows: [
              for (final g in gaps)
                DataRow(
                  cells: [
                    DataCell(Text(g.topic)),
                    DataCell(Text('${g.coverageCount}')),
                    DataCell(Text('${g.targetCoverage}')),
                    DataCell(Text(g.candidatePacks.join(', '))),
                    DataCell(Text(g.priorityScore.toStringAsFixed(1))),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
