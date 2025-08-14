import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FirstLaunchOverlay extends StatelessWidget {
  final VoidCallback onClose;
  const FirstLaunchOverlay({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black87,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Welcome',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Progress - track results\nTraining Packs - practice spots\nAnalyzer - review any hand',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onClose,
                  child: const Text('Got it'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void showFirstLaunchOverlay(BuildContext context, VoidCallback onClose) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => FirstLaunchOverlay(
      onClose: () {
        entry.remove();
        onClose();
      },
    ),
  );
  overlay.insert(entry);
}
