import 'package:flutter/material.dart';

import '../screens/skill_tree_screen.dart';

class SkillTreeMainMenuEntry extends StatelessWidget {
  const SkillTreeMainMenuEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SkillTreeScreen(category: 'Push/Fold'),
            ),
          );
        },
        icon: const Text('🧠', style: TextStyle(fontSize: 20)),
        label: const Text('Push/Fold Path'),
      ),
    );
  }
}
