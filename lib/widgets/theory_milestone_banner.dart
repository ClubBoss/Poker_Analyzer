import 'dart:async';
import 'package:flutter/material.dart';

import '../services/theory_milestone_unlocker.dart';

/// Listens to [TheoryMilestoneUnlocker.stream] and shows a temporary
/// banner when new milestones are unlocked.
class TheoryMilestoneBanner extends StatefulWidget {
  final TheoryMilestoneUnlocker unlocker;
  final Duration minInterval;
  const TheoryMilestoneBanner({
    super.key,
    required this.unlocker,
    this.minInterval = const Duration(seconds: 5),
  });

  @override
  State<TheoryMilestoneBanner> createState() => _TheoryMilestoneBannerState();
}

class _TheoryMilestoneBannerState extends State<TheoryMilestoneBanner> {
  StreamSubscription<TheoryMilestoneEvent>? _sub;
  DateTime? _lastShown;
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    _sub = widget.unlocker.stream.listen(_handleEvent);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _entry?.remove();
    super.dispose();
  }

  void _handleEvent(TheoryMilestoneEvent event) {
    final now = DateTime.now();
    if (_lastShown != null &&
        now.difference(_lastShown!) < widget.minInterval) {
      return;
    }
    _lastShown = now;
    _entry?.remove();
    _entry = _createEntry(event);
    Overlay.of(context).insert(_entry!);
  }

  OverlayEntry _createEntry(TheoryMilestoneEvent event) {
    return OverlayEntry(
      builder: (_) => _MilestoneBannerCard(
        event: event,
        onCompleted: () {
          _entry?.remove();
          _entry = null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _MilestoneBannerCard extends StatefulWidget {
  final TheoryMilestoneEvent event;
  final VoidCallback onCompleted;
  const _MilestoneBannerCard({required this.event, required this.onCompleted});

  @override
  State<_MilestoneBannerCard> createState() => _MilestoneBannerCardState();
}

class _MilestoneBannerCardState extends State<_MilestoneBannerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
    Future.delayed(const Duration(seconds: 3), () {
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

  String _message() {
    switch (widget.event.type) {
      case 'unlock':
        return '🔓 Кластер завершен!';
      case 'badge':
        return '🏅 Кластер пройден на 50%';
      default:
        final pct = (widget.event.progress * 100).toStringAsFixed(0);
        return '🎯 Прогресс $pct%';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 80,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _opacity,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.event.clusterName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _message(),
                    style: const TextStyle(color: Colors.white70),
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
