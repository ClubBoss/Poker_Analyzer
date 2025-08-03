import 'package:flutter/material.dart';

import '../helpers/poker_street_helper.dart';

/// Badge displaying the name of the current street.
class StreetIndicator extends StatelessWidget {
  final int street;
  const StreetIndicator({Key? key, required this.street}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = streetName(street);
    return Align(
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey(name),
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
