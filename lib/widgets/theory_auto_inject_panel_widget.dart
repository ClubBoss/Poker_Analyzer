import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/theory_gap_detector.dart';
import '../services/theory_auto_injector.dart';
import '../services/preferences_service.dart';

class TheoryAutoInjectPanelWidget extends StatefulWidget {
  const TheoryAutoInjectPanelWidget({
    super.key,
    required this.libraryDir,
    TheoryGapDetector? detector,
    TheoryAutoInjector? injector,
  })  : detector = detector ?? TheoryGapDetector(),
        injector = injector ?? TheoryAutoInjector();

  final TheoryGapDetector detector;
  final TheoryAutoInjector injector;
  final String libraryDir;

  @override
  State<TheoryAutoInjectPanelWidget> createState() =>
      _TheoryAutoInjectPanelWidgetState();
}

class _TheoryAutoInjectPanelWidgetState
    extends State<TheoryAutoInjectPanelWidget> {
  bool _dryRun = true;
  TheoryInjectReport? _report;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    final prefs = await PreferencesService.getInstance();
    final data = prefs.getString(SharedPrefsKeys.theoryInjectReport);
    if (data != null) {
      final json = jsonDecode(data) as Map<String, dynamic>;
      setState(() {
        _report = TheoryInjectReport.fromJson(json);
      });
    }
  }

  Future<void> _run() async {
    await widget.detector.detectGaps();
    final plan = widget.detector.exportRemediationPlan();
    final report = await widget.injector.inject(
      plan: plan,
      theoryIndex: widget.detector.theoryIndex,
      libraryDir: widget.libraryDir,
      minLinksPerPack: widget.detector.minTheoryLinksPerPack,
      dryRun: _dryRun,
    );
    setState(() => _report = report);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Dry Run'),
            Switch(
              value: _dryRun,
              onChanged: (v) => setState(() => _dryRun = v),
            ),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _run, child: const Text('Inject Now')),
          ],
        ),
        if (_report != null) ...[
          Text('Packs Updated: ${_report!.packsUpdated}'),
          Text('Links Added: ${_report!.linksAdded}'),
          if (_report!.errors.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Pack ID')),
                  DataColumn(label: Text('Error')),
                ],
                rows: [
                  for (final e in _report!.errors.entries)
                    DataRow(
                      cells: [DataCell(Text(e.key)), DataCell(Text(e.value))],
                    ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
