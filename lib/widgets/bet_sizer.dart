import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BetSizer extends StatefulWidget {
  // chips-based API
  final double min; // chips
  final double max; // chips
  final double value; // chips
  final double bb; // chips in 1 BB
  final double pot; // chips
  final double stack; // chips
  final ValueChanged<double> onChanged;
  final VoidCallback onConfirm;
  final double? recall; // last chosen amount in chips; null = hidden
  final bool enableHotkeys;
  final bool adaptive;
  final int? street;
  final double? spr;

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
    this.adaptive = false,
    this.street,
    this.spr,
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

  List<Widget> _buildPresets() {
    final presets = <Widget>[];
    double clampv(double v) => _clamp(v);
    void add(String label, double v) =>
        presets.add(_presetButton(label, clampv(v)));

    if (widget.recall != null) {
      final v = widget.recall!.clamp(widget.min, widget.max).toDouble();
      presets.add(OutlinedButton(
        onPressed: () {
          _set(v);
        },
        child: const Text('Recall'),
      ));
    }

    if (!widget.adaptive || widget.street == null) {
      add('1/4', widget.pot * 0.25);
      add('1/2', widget.pot * 0.5);
      add('2/3', widget.pot * 2 / 3);
      add('3/4', widget.pot * 0.75);
      add('Pot', widget.pot);
      add('All-in', widget.stack);
      return presets;
    }

    final st = widget.street!;
    if (st == 0) {
      add('2.5BB', widget.bb * 2.5);
      add('3BB', widget.bb * 3.0);
      add('3.5BB', widget.bb * 3.5);
      add('4BB', widget.bb * 4.0);
      add('All-in', widget.stack);
      return presets;
    }

    final spr =
        (widget.spr ?? (widget.pot > 0 ? widget.stack / widget.pot : 9999))
            .toDouble();
    if (spr >= 6) {
      add('1/3', widget.pot / 3);
      add('1/2', widget.pot * 0.5);
      add('2/3', widget.pot * 2 / 3);
      add('3/4', widget.pot * 0.75);
      add('Pot', widget.pot);
    } else if (spr >= 3) {
      add('1/2', widget.pot * 0.5);
      add('2/3', widget.pot * 2 / 3);
      add('3/4', widget.pot * 0.75);
      add('Pot', widget.pot);
      add('All-in', widget.stack);
    } else {
      add('2/3', widget.pot * 2 / 3);
      add('3/4', widget.pot * 0.75);
      add('Pot', widget.pot);
      add('All-in', widget.stack);
    }
    return presets;
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
          children: _buildPresets(),
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
