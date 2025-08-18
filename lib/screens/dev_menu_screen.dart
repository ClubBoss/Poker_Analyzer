import 'package:flutter/material.dart';

import 'dev_menu/booster_section.dart';
import 'dev_menu/coverage_section.dart';
import 'dev_menu/dev_menu_section.dart';
import 'dev_menu/pack_generation_section.dart';
import 'dev_menu/debug_tools_section.dart';

class DevMenuScreen extends StatelessWidget {
  const DevMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <DevMenuSection>[
      DevMenuSection(
        title: 'Training Pack Generator',
        builder: (_) => const PackGenerationSection(),
      ),
      DevMenuSection(
        title: 'Coverage Tools',
        builder: (_) => const CoverageSection(),
      ),
      DevMenuSection(
        title: 'Booster Tools',
        builder: (_) => const BoosterSection(),
      ),
      DevMenuSection(
        title: 'Debug Tools',
        builder: (_) => const DebugToolsSection(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Dev Menu')),
      backgroundColor: const Color(0xFF121212),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final s in sections)
            ExpansionTile(title: Text(s.title), children: [s.builder(context)]),
        ],
      ),
    );
  }
}
