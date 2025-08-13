import 'package:flutter/material.dart';
import '../services/pack_generator_service.dart';

class PresetRangeButtons extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  const PresetRangeButtons(
      {super.key, required this.selected, required this.onChanged});

  static const Set<String> _tightRange = {
    '22',
    '33',
    '44',
    '55',
    '66',
    '77',
    '88',
    '99',
    'TT',
    'JJ',
    'QQ',
    'KK',
    'AA',
    'A8s',
    'ATo',
    'KTs',
    'KJo'
  };

  void _applyTight() => onChanged({..._tightRange});

  void _applyLoosen() {
    final list = PackGeneratorService.handRanking;
    final addCount = (169 * 0.05).round();
    final newSet = Set<String>.from(selected);
    var added = 0;
    for (final h in list) {
      if (!newSet.contains(h)) {
        newSet.add(h);
        if (++added >= addCount) break;
      }
    }
    onChanged(newSet);
  }

  void _applyClear() => onChanged({});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(onPressed: _applyTight, child: const Text('Tight')),
        ElevatedButton(onPressed: _applyLoosen, child: const Text('Loosen')),
        ElevatedButton(onPressed: _applyClear, child: const Text('Clear')),
      ],
    );
  }
}
