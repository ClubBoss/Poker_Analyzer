import 'package:flutter/material.dart';

/// Small HUD overlay showing current street, pot and effective stack.
class HudOverlay extends StatelessWidget {
  final String streetName;
  final String potText;
  final String stackText;

  const HudOverlay({
    Key? key,
    required this.streetName,
    required this.potText,
    required this.stackText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey('$streetName-$potText-$stackText'),
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(streetName),
              Text('Pot: $potText'),
              Text('Eff: $stackText'),
            ],
          ),
        ),
      ),
    );
  }
}
