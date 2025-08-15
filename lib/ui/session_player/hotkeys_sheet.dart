import 'package:flutter/material.dart';

class HotkeysSheet extends StatelessWidget {
  const HotkeysSheet({super.key});

  @override
  Widget build(BuildContext context) {
    Widget row(String k, String d) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Text(k, style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(d, style: const TextStyle(color: Colors.white))),
            ],
          ),
        );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Hotkeys',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              row('1 / 2 / 3', 'Choose action'),
              row('Enter / Space', 'Next after answer'),
              row('H', 'Toggle "Why?"'),
              row('A', 'Toggle Auto-next'),
              row('T', 'Toggle Answer timer'),
              const Divider(height: 24),
              const Text('BetSizer',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              row('1', 'Recall last size (if available)'),
              row('2..6',
                  'Presets (1/4, 1/2, 2/3, 3/4, Pot) or Adaptive presets'),
              row('L', 'All-in'),
              row('- / +', '±1BB'),
              row('[ / ]', '±0.5BB'),
              row('Enter', 'Confirm size'),
              row('Esc', 'Close dialog'),
            ],
          ),
        ),
      ),
    );
  }
}

