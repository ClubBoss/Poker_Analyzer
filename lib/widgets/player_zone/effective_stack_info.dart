import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/pot_sync_service.dart';

/// Displays the effective stack size with a tooltip explaining its meaning.
class EffectiveStackInfo extends StatelessWidget {
  final String street;
  final TextStyle style;

  const EffectiveStackInfo({
    Key? key,
    required this.street,
    required this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final potSync = context.watch<PotSyncService>();
    final eff = potSync.effectiveStacks[street];
    final effText = eff != null ? eff.toDouble().toStringAsFixed(1) : '--';
    final platform = Theme.of(context).platform;
    final isMobile =
        platform == TargetPlatform.android || platform == TargetPlatform.iOS;
    return Tooltip(
      triggerMode:
          isMobile ? TooltipTriggerMode.longPress : TooltipTriggerMode.hover,
      message:
          'Эффективный стек — минимальный стек между вами и соперником. Используется при пуш/фолд.',
      child: Text(
        'Eff. stack: $effText BB',
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }
}
