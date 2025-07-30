import 'package:flutter/widgets.dart';

/// Lightweight goal representing short-term XP reward.
class XPGuidedGoal {
  final String id;
  final String label;
  final int xp;
  final String source;
  final VoidCallback onComplete;

  const XPGuidedGoal({
    required this.id,
    required this.label,
    required this.xp,
    required this.source,
    required this.onComplete,
  });
}
