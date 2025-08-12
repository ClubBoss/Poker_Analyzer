import 'package:flutter/material.dart';

class MistakeEmptyState extends StatefulWidget {
  const MistakeEmptyState({super.key});

  @override
  State<MistakeEmptyState> createState() => _MistakeEmptyStateState();
}

class _MistakeEmptyStateState extends State<MistakeEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    return Center(
      child: FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: animation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events, color: Colors.amberAccent, size: 64),
                SizedBox(height: 12),
                Text(
                  'Вы отлично справились! Ошибок не найдено 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
