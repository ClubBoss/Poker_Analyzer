import 'package:flutter/material.dart';

class MistakeEmptyState extends StatelessWidget {
  const MistakeEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.emoji_events, color: Colors.amberAccent, size: 64),
          SizedBox(height: 12),
          Text(
            'Ошибок нет!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Ты отлично сыграл! Ни одной ошибки за выбранный период.',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
