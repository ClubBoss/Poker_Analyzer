import 'package:flutter/material.dart';

class LessonOnboardingOverlay extends StatefulWidget {
  final VoidCallback onDismiss;
  const LessonOnboardingOverlay({super.key, required this.onDismiss});

  @override
  State<LessonOnboardingOverlay> createState() => _LessonOnboardingOverlayState();
}

class _LessonOnboardingOverlayState extends State<LessonOnboardingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  Future<void> _close() async {
    await _controller.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? Colors.black.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8);
    final cardColor = isDark ? Colors.black54 : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondary = isDark ? Colors.white70 : Colors.black54;
    return Positioned.fill(
      child: FadeTransition(
        opacity: _controller,
        child: Material(
          color: bgColor,
          child: InkWell(
            onTap: _close,
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DefaultTextStyle(
                  style: TextStyle(color: textColor),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Как работают шаги урока',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '1. Изучите цель шага и выполните тренировку.\n'
                        '2. После ответа получите фидбек и XP.\n'
                        '3. Откроется резюме и следующий шаг.',
                        style: TextStyle(color: secondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Нажмите в любом месте, чтобы продолжить',
                        style: TextStyle(color: secondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void showLessonOnboardingOverlay(BuildContext context, {VoidCallback? onDismiss}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => LessonOnboardingOverlay(
      onDismiss: () {
        entry.remove();
        onDismiss?.call();
      },
    ),
  );
  overlay.insert(entry);
}
