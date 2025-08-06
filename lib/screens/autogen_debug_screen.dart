import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/autogen_realtime_stats_panel.dart';
import '../widgets/inline_report_viewer_widget.dart';

/// Debug screen that monitors autogeneration progress.
class AutogenDebugScreen extends StatelessWidget {
  const AutogenDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Autogen Debug')),
      backgroundColor: AppColors.background,
      body: Column(
        children: const [
          Expanded(child: Center(child: Text('Autogen controls placeholder'))),
          AutogenRealtimeStatsPanel(),
          SizedBox(height: 200, child: InlineReportViewerWidget()),
        ],
      ),
    );
  }
}

