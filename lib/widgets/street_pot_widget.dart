import 'package:flutter/material.dart';

/// Displays pot size for a specific street in the history panel.
class StreetPotWidget extends StatelessWidget {
  final int streetIndex;
  final int potSize;

  const StreetPotWidget({
    super.key,
    required this.streetIndex,
    required this.potSize,
  });

  String get _streetName {
    const names = ['Префлоп', 'Флоп', 'Тёрн', 'Ривер'];
    if (streetIndex >= 0 && streetIndex < names.length) {
      return names[streetIndex];
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (potSize <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        '$_streetName пот: $potSize',
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }
}
