import 'package:flutter/material.dart';

class StreetHudBar extends StatelessWidget {
  final List<double> spr;
  final List<double> eff;
  final List<double?> potOdds;
  final int currentStreet;
  const StreetHudBar({super.key, required this.spr, required this.eff, required this.potOdds, required this.currentStreet});

  @override
  Widget build(BuildContext ctx) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(4, (i) {
          final label = ['P', 'F', 'T', 'R'][i];
          final color = i == currentStreet ? Colors.amber : Colors.white54;
          final sprText = spr[i] <= 0 ? '–' : spr[i].toStringAsFixed(1);
          final po = potOdds[i];
          final poText = po == null ? '–' : '${po.toStringAsFixed(1)} %';
          return Column(children: [
            Text('$label', style: TextStyle(color: color)),
            Text('SPR: $sprText', style: TextStyle(color: color, fontSize: 12)),
            Text('Eff: ${eff[i].toStringAsFixed(1)}',
                style: TextStyle(color: color, fontSize: 12)),
            Text('PO: $poText', style: TextStyle(color: color, fontSize: 12)),
          ]);
        }),
      );
}
