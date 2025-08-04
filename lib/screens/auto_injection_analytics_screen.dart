import 'package:flutter/material.dart';

import '../widgets/theory_auto_injection_analytics_panel.dart';

/// Debug screen showing analytics for theory auto-injections.
class AutoInjectionAnalyticsScreen extends StatelessWidget {
  const AutoInjectionAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auto Injection Analytics')),
      backgroundColor: const Color(0xFF121212),
      body: const TheoryAutoInjectionAnalyticsPanel(),
    );
  }
}

