import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/feedback_service.dart';

class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<FeedbackService>().data;
    if (data == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(data.icon, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(data.text, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
