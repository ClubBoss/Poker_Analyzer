import 'package:flutter/material.dart';

import 'confetti_overlay.dart';

Future<void> showUnlockProgressDialog(
  BuildContext context, {
  required double accuracyBefore,
  required double accuracyAfter,
  required int handsBefore,
  required int handsAfter,
  double? requiredAccuracy,
  int? minHands,
}) async {
  final accReq = requiredAccuracy;
  final handsReq = minHands;

  final neededAcc = accReq != null
      ? (accReq - accuracyAfter).clamp(0, double.infinity)
      : 0;
  final neededHands = handsReq != null
      ? (handsReq - handsAfter).clamp(0, double.infinity)
      : 0;

  final achieved = (neededAcc <= 0) && (neededHands <= 0);

  final remainingParts = <String>[];
  if (neededAcc > 0) {
    remainingParts.add('+${neededAcc.toStringAsFixed(0)}% точности');
  }
  if (neededHands > 0) {
    final h = neededHands.toInt();
    remainingParts.add(
      '$h ру${h == 1
          ? 'ка'
          : h < 5
          ? 'ки'
          : 'к'}',
    );
  }
  final remainingText = achieved
      ? 'Цель достигнута!'
      : 'Осталось: ${remainingParts.join(' и ')}';

  if (achieved) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showConfettiOverlay(context);
    });
  }

  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('📈 Прогресс разблокировки'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Точность: ${accuracyBefore.toStringAsFixed(0)}% → ${accuracyAfter.toStringAsFixed(0)}%'
            '${accReq != null ? ' / ≥${accReq.toStringAsFixed(0)}%' : ''}',
          ),
          Text(
            'Руки: $handsBefore → $handsAfter'
            '${handsReq != null ? ' / ≥$handsReq' : ''}',
          ),
          const SizedBox(height: 12),
          Text(remainingText),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
