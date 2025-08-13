import 'package:flutter/material.dart';

import '../screens/tag_insight_screen.dart';

/// Simple visual badge for displaying a training tag.
class TagBadge extends StatelessWidget {
  final String tag;
  final VoidCallback? onTap;
  const TagBadge(this.tag, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ??
          () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TagInsightScreen(tag: tag)),
              ),
      child: Chip(
        label: Text(
          tag,
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
        backgroundColor: const Color(0xFF3A3B3E),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      ),
    );
  }
}
