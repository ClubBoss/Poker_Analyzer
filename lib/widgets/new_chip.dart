import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NewChip extends StatelessWidget {
  const NewChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Новое',
        style: TextStyle(color: Colors.black, fontSize: 12),
      ),
    );
  }
}
