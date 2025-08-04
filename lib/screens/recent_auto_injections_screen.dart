import 'package:flutter/material.dart';

import '../widgets/recent_theory_auto_injections_panel.dart';

/// Temporary debug screen showing recent theory auto-injection events.
class RecentAutoInjectionsScreen extends StatelessWidget {
  const RecentAutoInjectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recent Auto Injections')),
      backgroundColor: const Color(0xFF121212),
      body: const RecentTheoryAutoInjectionsPanel(),
    );
  }
}
