import 'package:flutter/material.dart';

Future<String?> showActionBottomSheet(BuildContext context) {
  const actions = [
    {'label': 'Fold', 'value': 'fold', 'icon': '❌'},
    {'label': 'Call', 'value': 'call', 'icon': '📞'},
    {'label': 'Check', 'value': 'check', 'icon': '✅'},
    {'label': 'Bet', 'value': 'bet', 'icon': '💰'},
    {'label': 'Raise', 'value': 'raise', 'icon': '📈'},
  ];
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
          for (int i = 0; i < actions.length; i++) ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, actions[i]['value'] as String),
              icon: Text(actions[i]['icon'] as String, style: const TextStyle(fontSize: 24)),
              label: Text(actions[i]['label'] as String, style: const TextStyle(fontSize: 20)),
            ),
            if (i != actions.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    ),
  );
}
