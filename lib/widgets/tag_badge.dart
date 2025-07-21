import 'package:flutter/material.dart';

/// Simple visual badge for displaying a training tag.
class TagBadge extends StatelessWidget {
  final String tag;
  const TagBadge(this.tag, {super.key});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        tag,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
      backgroundColor: const Color(0xFF3A3B3E),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
    );
  }
}
