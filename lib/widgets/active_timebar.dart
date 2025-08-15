import 'dart:async';
import 'package:flutter/material.dart';

class ActiveTimebar extends StatefulWidget {
  final int totalMs; // e.g. 10000
  final int startMs; // initial remaining (default = totalMs)
  final bool running; // start/stop timer
  final VoidCallback? onTimeout; // called once on reach 0
  const ActiveTimebar({
    super.key,
    required this.totalMs,
    this.startMs = -1,
    this.running = true,
    this.onTimeout,
  });
}

class _ActiveTimebarState extends State<ActiveTimebar> {
  late int _remaining;
  Timer? _timer;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.startMs >= 0 ? widget.startMs : widget.totalMs;
    _maybeStart();
  }

  @override
  void didUpdateWidget(covariant ActiveTimebar old) {
    super.didUpdateWidget(old);
    if (old.running != widget.running) {
      _maybeStart();
    }
  }

  void _maybeStart() {
    _timer?.cancel();
    if (!widget.running) return;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() {
        _remaining -= 100;
        if (_remaining <= 0) {
          _remaining = 0;
          if (!_fired) {
            _fired = true;
            _timer?.cancel();
            widget.onTimeout?.call();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.totalMs <= 0 ? 1 : widget.totalMs;
    final frac = _remaining / total;
    Color color;
    if (frac > 0.5) {
      color = Colors.green;
    } else if (frac > 0.2) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: frac.clamp(0.0, 1.0),
        minHeight: 4,
        backgroundColor: Colors.black26,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
