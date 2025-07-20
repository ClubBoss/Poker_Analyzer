import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../services/training_pack_play_controller.dart';

class PackResumeBanner extends StatelessWidget {
  const PackResumeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TrainingPackPlayController>(
      builder: (context, ctrl, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: ctrl.hasIncompleteSession,
          builder: (context, has, __) {
            final tpl = ctrl.template;
            if (!has || tpl == null) return const SizedBox.shrink();
            final accent = Theme.of(context).colorScheme.secondary;
            final l = AppLocalizations.of(context)!;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tpl.name,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 16)),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l.unfinishedSession,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => ctrl.resume(context),
                      style: ElevatedButton.styleFrom(backgroundColor: accent),
                      child: Text(l.resume),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
