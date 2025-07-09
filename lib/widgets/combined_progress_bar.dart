import 'package:flutter/material.dart';

class CombinedProgressBar extends StatelessWidget {
  final double evPct;
  final double icmPct;
  const CombinedProgressBar(this.evPct, this.icmPct, {super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Container(
        height: 6,
        color: Colors.white24,
        child: Stack(
          children: [
            FractionallySizedBox(
              widthFactor: (evPct / 100).clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(color: Colors.green),
            ),
            FractionallySizedBox(
              widthFactor: (icmPct / 100).clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(color: Colors.blue.withOpacity(.5)),
            ),
          ],
        ),
      ),
    );
  }
}

