import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/suggested_pack_service.dart';
import '../../services/training_session_service.dart';
import '../../screens/training_session_screen.dart';

class MainMenuSuggestedBanner extends StatelessWidget {
  final bool suggestedDismissed;
  final DateTime? dismissedDate;
  final VoidCallback onDismissed;
  final VoidCallback onClearDismissed;

  const MainMenuSuggestedBanner({
    super.key,
    required this.suggestedDismissed,
    required this.dismissedDate,
    required this.onDismissed,
    required this.onClearDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SuggestedPackService>();
    final tpl = service.template;
    final date = service.date;
    if (dismissedDate != null &&
        DateTime.now().difference(dismissedDate!).inDays >= 7 &&
        suggestedDismissed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onClearDismissed());
    }
    final show = !suggestedDismissed &&
        tpl != null &&
        date != null &&
        DateTime.now().difference(date).inDays < 6;
    if (!show) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Dismissible(
        key: const ValueKey('suggestedBanner'),
        direction: DismissDirection.horizontal,
        onDismissed: (_) => onDismissed(),
        child: Card(
          color: Colors.grey[850],
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Новая подборка тренировок!',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await context
                        .read<TrainingSessionService>()
                        .startSession(tpl);
                    if (!context.mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TrainingSessionScreen()),
                    );
                  },
                  child: const Text('Начать тренировку'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
