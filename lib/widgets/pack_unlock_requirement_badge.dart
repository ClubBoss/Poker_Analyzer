import 'package:flutter/material.dart';

/// Small badge showing unlock requirements for a training pack.
class PackUnlockRequirementBadge extends StatelessWidget {
  final String text;
  final String? tooltip;
  const PackUnlockRequirementBadge({
    super.key,
    required this.text,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock, size: 14, color: Colors.white70),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
    return tooltip == null ? child : Tooltip(message: tooltip!, child: child);
  }
}
