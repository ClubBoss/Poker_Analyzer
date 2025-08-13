import 'package:flutter/material.dart';

/// Small overlay banner prompting the user to learn high priority theory gaps.
class SkillGapOverlayBanner extends StatefulWidget {
  final List<String> tags;
  final VoidCallback onDismiss;
  final VoidCallback onOpen;

  const SkillGapOverlayBanner({
    super.key,
    required this.tags,
    required this.onDismiss,
    required this.onOpen,
  });

  @override
  State<SkillGapOverlayBanner> createState() => _SkillGapOverlayBannerState();
}

class _SkillGapOverlayBannerState extends State<SkillGapOverlayBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    Future.delayed(const Duration(seconds: 15), widget.onDismiss);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    final text = widget.tags.take(2).join(', ');
    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: SafeArea(
        child: FadeTransition(
          opacity: _anim,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '🎯 Усильте незакрытую тему: $text',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: widget.onOpen,
                    style: ElevatedButton.styleFrom(backgroundColor: accent),
                    child: const Text('Пройти бустер'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
