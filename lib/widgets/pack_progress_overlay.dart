import 'package:flutter/material.dart';
import '../services/smart_resume_engine.dart';

class PackProgressOverlay extends StatelessWidget {
  final String templateId;
  final double size;
  const PackProgressOverlay({
    super.key,
    required this.templateId,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: SmartResumeEngine.instance.getProgressPercent(templateId),
      builder: (context, snapshot) {
        final pct = snapshot.data ?? 0;
        if (pct <= 0) return const SizedBox.shrink();
        final ring = SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: pct / 100,
            strokeWidth: 3,
            color: Theme.of(context).colorScheme.secondary,
            backgroundColor: Colors.black26,
          ),
        );
        final child = Stack(
          alignment: Alignment.center,
          children: [
            ring,
            Text('$pct%', style: const TextStyle(fontSize: 10)),
          ],
        );
        return Tooltip(message: 'Completed $pct% of this pack', child: child);
      },
    );
  }
}
