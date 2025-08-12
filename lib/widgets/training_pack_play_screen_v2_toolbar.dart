import 'package:flutter/material.dart';
import '../services/app_settings_service.dart';
import '../services/mistake_hint_service.dart';
import '../services/user_preferences_service.dart';
import 'package:provider/provider.dart';

class TrainingPackPlayScreenV2Toolbar extends StatelessWidget {
  final String title;
  final int index;
  final int total;
  final VoidCallback onExit;
  final VoidCallback onModeToggle;
  final VoidCallback onAdaptiveToggle;
  final bool adaptive;
  final bool mini;
  final int? streetIndex;
  const TrainingPackPlayScreenV2Toolbar({
    super.key,
    required this.title,
    required this.index,
    required this.total,
    required this.onExit,
    required this.onModeToggle,
    required this.onAdaptiveToggle,
    required this.adaptive,
    this.mini = false,
    this.streetIndex,
  });

  bool _showHintButton(BuildContext context) =>
      !context.read<UserPreferencesService>().showActionHints;

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
            .withValues(alpha: 0.9),
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
                          ['Preflop', 'Flop', 'Turn', 'River'][streetIndex!],
                          style: textStyle.copyWith(fontSize: mini ? 10 : 12),
                        ),
                      ),
                  ],
                ),
              ),
              if (_showHintButton(context))
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
                icon: Icon(
                    adaptive ? Icons.scatter_plot : Icons.scatter_plot_outlined),
                color: adaptive
                    ? Theme.of(context).colorScheme.primary
                    : iconColor,
                tooltip: 'Adaptive mode',
                onPressed: onAdaptiveToggle,
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
