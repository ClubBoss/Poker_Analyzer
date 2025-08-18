import 'package:flutter/material.dart';

class AchievementRewardPopup extends StatefulWidget {
  final String title;
  final int xp;
  final int coins;
  final IconData icon;
  final VoidCallback onCompleted;

  const AchievementRewardPopup({
    super.key,
    required this.title,
    required this.xp,
    required this.coins,
    required this.icon,
    required this.onCompleted,
  });

  @override
  State<AchievementRewardPopup> createState() => _AchievementRewardPopupState();
}

class _AchievementRewardPopupState extends State<AchievementRewardPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _offset = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onCompleted());
      } else {
        widget.onCompleted();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: Colors.white);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 40),
        child: SlideTransition(
          position: _offset,
          child: FadeTransition(
            opacity: _opacity,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, color: Colors.orangeAccent),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: style.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (widget.xp > 0)
                              Text('+${widget.xp} XP', style: style),
                            if (widget.xp > 0 && widget.coins > 0)
                              const SizedBox(width: 8),
                            if (widget.coins > 0)
                              Text('+${widget.coins} coins', style: style),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void showAchievementRewardPopup(
  BuildContext context, {
  required IconData icon,
  required String title,
  int xp = 0,
  int coins = 0,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => AchievementRewardPopup(
      icon: icon,
      title: title,
      xp: xp,
      coins: coins,
      onCompleted: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}
