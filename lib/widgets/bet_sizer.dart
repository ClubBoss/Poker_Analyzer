import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BetSizer extends StatefulWidget {
  // chips-based API
  final double min;    // chips
  final double max;    // chips
  final double value;  // chips
  final double bb;     // chips in 1 BB
  final double pot;    // chips
  final double stack;  // chips
  final ValueChanged<double> onChanged;
  final VoidCallback onConfirm;
  final double? recall; // last chosen amount in chips; null = hidden
  final bool enableHotkeys;

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
    this.recall,
    this.enableHotkeys = true,
  });

  @override
  State<BetSizer> createState() => _BetSizerState();
}

class _BetSizerState extends State<BetSizer> {
  late double _value;
  Timer? _repeat;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _value = _clamp(widget.value);
  }

  @override
  void didUpdateWidget(covariant BetSizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value ||
        oldWidget.min != widget.min ||
        oldWidget.max != widget.max) {
      _value = _clamp(widget.value);
    }
  }

  double _clamp(double v) => v.clamp(widget.min, widget.max);

  void _set(double v) {
    final nv = _clamp(v);
    if (nv == _value) return;
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

  void _onKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.digit1) {
      if (widget.recall != null) {
        _set(widget.recall!.clamp(widget.min, widget.max).toDouble());
      }
    } else if (key == LogicalKeyboardKey.digit2) {
      _set(_clamp(widget.pot * 0.25));
    } else if (key == LogicalKeyboardKey.digit3) {
      _set(_clamp(widget.pot * 0.5));
    } else if (key == LogicalKeyboardKey.digit4) {
      _set(_clamp(widget.pot * 2 / 3));
    } else if (key == LogicalKeyboardKey.digit5) {
      _set(_clamp(widget.pot * 0.75));
    } else if (key == LogicalKeyboardKey.digit6) {
      _set(_clamp(widget.pot));
    } else if (key == LogicalKeyboardKey.keyL) {
      _set(_clamp(widget.stack));
    } else if (key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract) {
      _change(-widget.bb);
    } else if (key == LogicalKeyboardKey.equal ||
        key == LogicalKeyboardKey.numpadAdd) {
      _change(widget.bb);
    } else if (key == LogicalKeyboardKey.bracketLeft) {
      _change(-widget.bb * 0.5);
    } else if (key == LogicalKeyboardKey.bracketRight) {
      _change(widget.bb * 0.5);
    } else if (key == LogicalKeyboardKey.enter) {
      widget.onConfirm();
    } else if (key == LogicalKeyboardKey.escape) {
      Navigator.maybePop(context);
    }
  }

  Widget _presetButton(String label, double target) {
    return OutlinedButton(
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
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bbValue = _value / widget.bb;
    final chips = _value.round();

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with live value
        Row(
          children: [
            const Text('Bet/Raise'),
            const Spacer(),
            Text('${bbValue.toStringAsFixed(1)} BB ($chips chips)'),
          ],
        ),
        const SizedBox(height: 8),

        // Presets
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (widget.recall != null)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {
                  final v =
                      widget.recall!.clamp(widget.min, widget.max).toDouble();
                  setState(() => _value = v);
                  widget.onChanged(v);
                },
                child: const Text('Recall'),
              ),
            _presetButton('1/4', _clamp(widget.pot * 0.25)),
            _presetButton('1/2', _clamp(widget.pot * 0.5)),
            _presetButton('2/3', _clamp(widget.pot * 2 / 3)),
            _presetButton('3/4', _clamp(widget.pot * 0.75)),
            _presetButton('Pot', _clamp(widget.pot)),
            _presetButton('All-in', _clamp(widget.stack)),
          ],
        ),
        const SizedBox(height: 8),

        // Slider
        Slider(
          value: _value,
          min: widget.min,
          max: widget.max,
          onChanged: _set,
        ),
        const SizedBox(height: 4),

        // BB steppers with auto-repeat
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

        // Actions
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

    if (!widget.enableHotkeys) return column;
    return RawKeyboardListener(
      focusNode: _focus,
      autofocus: true,
      onKey: _onKey,
      child: column,
    );
  }
}
