import 'package:flutter/material.dart';

class BetSizer extends StatefulWidget {
  final int pot;
  final int stackSize;
  final ValueChanged<int> onSelected;

  const BetSizer({
    Key? key,
    required this.pot,
    required this.stackSize,
    required this.onSelected,
  }) : super(key: key);

  @override
  State<BetSizer> createState() => _BetSizerState();
}

class _BetSizerState extends State<BetSizer> {
  double _value = 0;

  Widget _quickButton(String label, double fraction) {
    final int amount = (widget.pot * fraction).round().clamp(0, widget.stackSize);
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.white12),
      onPressed: () => widget.onSelected(amount),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }

  void _handleEnd(double val) {
    if (val > 0) {
      widget.onSelected(val.round());
      setState(() => _value = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _quickButton('33% Pot', 0.33),
            _quickButton('50% Pot', 0.5),
            _quickButton('75% Pot', 0.75),
            _quickButton('100% Pot', 1.0),
          ],
        ),
        const SizedBox(height: 12),
        Slider(
          value: _value,
          min: 0,
          max: widget.stackSize.toDouble(),
          divisions: widget.stackSize > 0 ? widget.stackSize : 1,
          label: _value.round().toString(),
          onChanged: (v) => setState(() => _value = v),
          onChangeEnd: _handleEnd,
        ),
        Text(
          _value.round().toString(),
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}
