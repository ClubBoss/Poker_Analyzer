import 'package:flutter/material.dart';
import 'package:poker_analyzer/ui/padding_constants.dart';

/// Small HUD overlay showing current street, pot and effective stack.
class HudOverlay extends StatelessWidget {
  final String streetName;
  final String potText;
  final String stackText;
  final String? sprText;

  const HudOverlay({
    Key? key,
    required this.streetName,
    required this.potText,
    required this.stackText,
    this.sprText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey('$streetName-$potText-$stackText-${sprText ?? ''}'),
        margin: kCardPadding,
        padding: kCardPadding,
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Pot: $potText'),
                  if (sprText != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      sprText!,
                      style: const TextStyle(
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              Text('Eff: $stackText'),
            ],
          ),
        ),
      ),
    );
  }
}
