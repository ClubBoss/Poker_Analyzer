import 'package:flutter/material.dart';

/// Compact representation of a fully completed stage that can be expanded.
class FoldedStageWidget extends StatelessWidget {
  final int level;
  final int nodeCount;
  final VoidCallback? onTap;

  const FoldedStageWidget({
    super.key,
    required this.level,
    required this.nodeCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Level $level',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text('$nodeCount nodes'),
          ],
        ),
      ),
    );
  }
}
