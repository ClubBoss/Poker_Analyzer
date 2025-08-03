import 'package:flutter/material.dart';
import 'dark_alert_dialog.dart';
import 'confetti_overlay.dart';

class RewardDialog extends StatelessWidget {
  final int reward;
  const RewardDialog({super.key, required this.reward});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showConfettiOverlay(context);
    });
    return DarkAlertDialog(
      title: const Text('Reward'),
      content: Text('+$reward'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
