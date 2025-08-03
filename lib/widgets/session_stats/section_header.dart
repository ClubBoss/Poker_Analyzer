import 'package:flutter/material.dart';

/// Standard section header used throughout the session stats screen.
class SessionSectionHeader extends StatelessWidget {
  final String text;

  const SessionSectionHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: Colors.white70));
  }
}
