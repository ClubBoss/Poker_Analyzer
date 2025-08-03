import 'package:flutter/material.dart';

/// A widget that lets the user pick a bet size using common fractions or a
/// slider. When a valid amount is chosen the [onSelected] callback is invoked
/// with the chosen amount.
class BetSizer extends StatefulWidget {
  final int stackSize;
  final int pot;
  final ValueChanged<double> onSelected;

  const BetSizer({
    super.key,
    required this.stackSize,
    required this.pot,
    required this.onSelected,
  });

  @override
  State<BetSizer> createState() => _BetSizerState();
}

class _BetSizerState extends State<BetSizer> {
  double _slider = 0;

  void _onSliderChange(double value) {
    setState(() => _slider = value);
    if (value > 0) {
      widget.onSelected(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int max = widget.stackSize;
    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final f in [1 / 3, 0.5, 0.75, 1.0])
              OutlinedButton(
                onPressed: () {
                  final amount = widget.pot * f;
                  widget.onSelected(amount);
                },
                child: Text('${(f * 100).round()}%'),
              ),
          ],
        ),
        Slider(
          value: _slider,
          min: 0,
          max: max.toDouble(),
          divisions: max,
          label: _slider.round().toString(),
          onChanged: _onSliderChange,
        ),
        Text('Amount: ${_slider.round()}',
            style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}

