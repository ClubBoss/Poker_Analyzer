import 'dart:async';
import 'package:flutter/material.dart';

class BetSizer extends StatefulWidget {
  final double min;    // chips
  final double max;    // chips
  final double value;  // chips
  final double bb;     // chips in 1 BB
  final double pot;    // chips
  final double stack;  // chips
  final ValueChanged<double> onChanged;
  final VoidCallback onConfirm;

  const BetSizer({
    super.key,
    required this.min,
    required this.max,
    required this.value,
    required this.bb,
    required this.pot,
    required this.stack,
    required this.onChanged,
    required this.onConfirm,
  });

  @override
  State<BetSizer> createState() => _BetSizerState();
}

class _BetSizerState extends State<BetSizer> {
  late double _value;
  Timer? _repeat;

  @override
  void initState() {
    super.initState();
    _value = _clamp(widget.value);
  }

  @override
  void didUpdateWidget(covariant BetSizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _value = _clamp(widget.value);
    }
  }

  double _clamp(double v) => v.clamp(widget.min, widget.max);

  void _set(double v) {
    final nv = _clamp(v);
    setState(() => _value = nv);
    widget.onChanged(nv);
  }

  void _change(double delta) => _set(_value + delta);

  void _startRepeat(double delta) {
    _repeat?.cancel();
    _repeat = Timer.periodic(const Duration(milliseconds: 120), (_) {
      _change(delta);
    });
  }

  void _stopRepeat() {
    _repeat?.cancel();
    _repeat = null;
  }

  Widget _presetButton(String label, double target) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white54),
      ),
      onPressed: () => _set(target),
      child: Text(label),
    );
  }

  Widget _stepper(String label, double delta) {
    return Listener(
      onPointerDown: (_) {
        _change(delta);
        _startRepeat(delta);
      },
      onPointerUp: (_) => _stopRepeat(),
      onPointerCancel: (_) => _stopRepeat(),
      child: OutlinedButton(
        onPressed: () => _change(delta),
        child: Text(label),
      ),
    );
  }

  @override
  void dispose() {
    _stopRepeat();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bbValue = _value / widget.bb;
    final chips = _value.round();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Text('Bet/Raise'),
            const Spacer(),
            Text('${bbValue.toStringAsFixed(1)} BB ($chips chips)'),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _presetButton('1/4', _clamp(widget.pot * 0.25)),
            _presetButton('1/2', _clamp(widget.pot * 0.5)),
            _presetButton('2/3', _clamp(widget.pot * 2 / 3)),
            _presetButton('3/4', _clamp(widget.pot * 0.75)),
            _presetButton('Pot', _clamp(widget.pot)),
            _presetButton('All-in', _clamp(widget.stack)),
          ],
        ),
        Slider(
          value: _value,
          min: widget.min,
          max: widget.max,
          onChanged: _set,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _stepper('-1BB', -widget.bb),
            _stepper('-0.5BB', -widget.bb * 0.5),
            _stepper('+0.5BB', widget.bb * 0.5),
            _stepper('+1BB', widget.bb),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.maybePop(context),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: widget.onConfirm,
              child: const Text('Confirm'),
            ),
          ],
        ),
      ],
    );
  }
}

