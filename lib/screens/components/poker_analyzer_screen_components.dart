import 'package:flutter/material.dart';

import '../../models/player_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/constants.dart';
import '../../widgets/hand_completion_indicator.dart';
import '../poker_analyzer/action_controls_widget.dart';
import '../poker_analyzer/board_controls_widget.dart';
import '../poker_analyzer/action_editor_widget.dart';
import '../poker_analyzer/evaluation_panel_widget.dart';

class AnalyzerTableAreaWidget extends StatelessWidget {
  final bool landscape;
  final double uiScale;
  const AnalyzerTableAreaWidget({
    super.key,
    required this.landscape,
    required this.uiScale,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 7,
      child: landscape
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Transform.scale(
                    scale: uiScale,
                    alignment: Alignment.topCenter,
                    child: const BoardControls(),
                  ),
                ),
                const Expanded(child: ActionControls()),
              ],
            )
          : Column(
              children: [
                Transform.scale(
                  scale: uiScale,
                  alignment: Alignment.topCenter,
                  child: const BoardControls(),
                ),
                const Expanded(child: ActionControls()),
              ],
            ),
    );
  }
}

class AnalyzerSidebarWidget extends StatelessWidget {
  const AnalyzerSidebarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Column(
        children: const [
          Expanded(child: ActionEditor()),
          Expanded(child: EvaluationPanel()),
        ],
      ),
    );
  }
}

class SmartInboxRegion extends StatelessWidget {
  final String? message;
  const SmartInboxRegion({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return _InfoBanner(message: message!);
  }
}

class AnalyzerTopHUD extends StatelessWidget {
  final String handName;
  final int playerCount;
  final String streetName;
  final VoidCallback onEdit;
  final double handCompletionProgress;
  final int numberOfPlayers;
  final Map<int, String> playerPositions;
  final Map<int, PlayerType> playerTypes;
  final ValueChanged<int>? onPlayerCountChanged;
  final bool disabled;
  final int handProgressStep;

  const AnalyzerTopHUD({
    super.key,
    required this.handName,
    required this.playerCount,
    required this.streetName,
    required this.onEdit,
    required this.handCompletionProgress,
    required this.numberOfPlayers,
    required this.playerPositions,
    required this.playerTypes,
    this.onPlayerCountChanged,
    this.disabled = false,
    required this.handProgressStep,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HandHeaderSection(
          handName: handName,
          playerCount: playerCount,
          streetName: streetName,
          onEdit: onEdit,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: HandCompletionIndicator(progress: handCompletionProgress),
        ),
        _PlayerCountSelector(
          numberOfPlayers: numberOfPlayers,
          playerPositions: playerPositions,
          playerTypes: playerTypes,
          onChanged: onPlayerCountChanged,
          disabled: disabled,
        ),
        _HandProgressIndicator(step: handProgressStep),
      ],
    );
  }
}

class _HandHeaderSection extends StatelessWidget {
  final String handName;
  final int playerCount;
  final String streetName;
  final VoidCallback onEdit;
  const _HandHeaderSection({
    required this.handName,
    required this.playerCount,
    required this.streetName,
    required this.onEdit,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.padding16),
      child: Card(
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radius8)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(handName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('$playerCount players • $streetName',
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: onEdit),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerCountSelector extends StatelessWidget {
  final int numberOfPlayers;
  final Map<int, String> playerPositions;
  final Map<int, PlayerType> playerTypes;
  final ValueChanged<int>? onChanged;
  final bool disabled;
  const _PlayerCountSelector({
    required this.numberOfPlayers,
    required this.playerPositions,
    required this.playerTypes,
    this.onChanged,
    this.disabled = false,
  });
  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: numberOfPlayers,
      dropdownColor: Colors.black,
      style: const TextStyle(color: Colors.white),
      iconEnabledColor: Colors.white,
      items: [
        for (int i = 2; i <= 10; i++)
          DropdownMenuItem(value: i, child: Text('Игроков: $i'))
      ],
      onChanged: disabled
          ? null
          : (value) {
              if (value != null && onChanged != null) onChanged!(value);
            },
    );
  }
}

class _HandProgressIndicator extends StatelessWidget {
  final int step;
  const _HandProgressIndicator({required this.step});
  @override
  Widget build(BuildContext context) {
    const labels = ['Игроки', 'Карты', 'Действия', 'Шоудаун'];
    const icons = [Icons.people, Icons.style, Icons.list_alt, Icons.flag];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(labels.length, (i) {
          final active = step >= i;
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? Colors.blueAccent : Colors.white12,
                  ),
                  child: Icon(icons[i], size: 16, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: active ? Colors.white : Colors.white54,
                        fontSize: 12)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String message;
  const _InfoBanner({required this.message});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppConstants.radius8),
        ),
        child: Text(message, style: const TextStyle(color: Colors.white70)),
      ),
    );
  }
}

