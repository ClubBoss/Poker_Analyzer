import 'package:flutter/material.dart';
import '../services/app_settings_service.dart';
import '../services/mistake_hint_service.dart';
import '../user_preferences.dart';
import '../helpers/poker_street_helper.dart';

class TrainingPackPlayScreenV2Toolbar extends StatelessWidget {
  final String title;
  final int index;
  final int total;
  final VoidCallback onExit;
  final VoidCallback onModeToggle;
  final bool mini;
  final int? streetIndex;
  const TrainingPackPlayScreenV2Toolbar({
    super.key,
    required this.title,
    required this.index,
    required this.total,
    required this.onExit,
    required this.onModeToggle,
    this.mini = false,
    this.streetIndex,
  });

  bool get _showHintButton => !UserPreferences.instance.showActionHints;

  @override
  Widget build(BuildContext context) {
    final isIcm = AppSettingsService.instance.useIcm;
    final textStyle = TextStyle(
      fontSize: mini ? 12 : 14,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface,
    );
    final iconColor = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
          onExit();
        }
      },
      child: Container(
        color: Theme.of(context)
            .colorScheme
            .surface
            .withOpacity(0.9),
        padding: EdgeInsets.symmetric(
            horizontal: mini ? 8 : 16, vertical: mini ? 4 : 8),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$title — ${index + 1}/$total',
                      style: textStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (streetIndex != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          streetName(streetIndex!),
                          style: textStyle.copyWith(fontSize: mini ? 10 : 12),
                        ),
                      ),
                  ],
                ),
              ),
              if (_showHintButton)
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  color: iconColor,
                  tooltip: 'Hint',
                  onPressed: () {
                    final hint = MistakeHintService.instance.getHint();
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(hint)));
                  },
                ),
              IconButton(
                icon: Icon(isIcm ? Icons.monetization_on : Icons.stacked_line_chart),
                color: iconColor,
                tooltip: isIcm ? 'ICM' : 'EV',
                onPressed: onModeToggle,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                color: iconColor,
                tooltip: 'Exit',
                onPressed: onExit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
