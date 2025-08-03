import 'package:flutter/material.dart';

import '../models/poker_actions.dart';

Future<String?> showActionBottomSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.grey[900],
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in pokerActions.asMap().entries) ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, entry.value.value),
              icon: Text(entry.value.icon, style: const TextStyle(fontSize: 24)),
              label:
                  Text(entry.value.label, style: const TextStyle(fontSize: 20)),
            ),
            if (entry.key != pokerActions.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    ),
  );
}
