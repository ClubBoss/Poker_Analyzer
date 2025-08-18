import 'package:flutter/material.dart';
import '../../models/game_type.dart';
import '../../models/pack_chart_sort_option.dart';
import '../../theme/app_colors.dart';
import '../../helpers/color_utils.dart';

class PackComparisonFilters extends StatelessWidget {
  final bool forgottenOnly;
  final ValueChanged<bool> onForgottenChanged;
  final PackChartSort chartSort;
  final ValueChanged<PackChartSort?> onSortChanged;
  final GameType? typeFilter;
  final ValueChanged<GameType?> onTypeChanged;
  final int diffFilter;
  final ValueChanged<int> onDiffChanged;
  final String colorFilter;
  final ValueChanged<String?> onColorChanged;

  const PackComparisonFilters({
    super.key,
    required this.forgottenOnly,
    required this.onForgottenChanged,
    required this.chartSort,
    required this.onSortChanged,
    required this.typeFilter,
    required this.onTypeChanged,
    required this.diffFilter,
    required this.onDiffChanged,
    required this.colorFilter,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Давно не повторял'),
          value: forgottenOnly,
          onChanged: onForgottenChanged,
          activeThumbColor: Colors.orange,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('Сортировка', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 8),
              DropdownButton<PackChartSort>(
                value: chartSort,
                dropdownColor: AppColors.cardBackground,
                style: const TextStyle(color: Colors.white),
                items: [
                  for (final s in PackChartSort.values)
                    DropdownMenuItem(value: s, child: Text(s.label)),
                ],
                onChanged: onSortChanged,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('Тип', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 8),
              DropdownButton<GameType?>(
                value: typeFilter,
                dropdownColor: AppColors.cardBackground,
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Все')),
                  DropdownMenuItem(
                    value: GameType.cash,
                    child: Text('Cash Game'),
                  ),
                  DropdownMenuItem(
                    value: GameType.tournament,
                    child: Text('Tournament'),
                  ),
                ],
                onChanged: onTypeChanged,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('Сложность', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: diffFilter,
                dropdownColor: AppColors.cardBackground,
                style: const TextStyle(color: Colors.white),
                onChanged: (v) => onDiffChanged(v ?? 0),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('All')),
                  DropdownMenuItem(value: 1, child: Text('Beginner')),
                  DropdownMenuItem(value: 2, child: Text('Intermediate')),
                  DropdownMenuItem(value: 3, child: Text('Advanced')),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text('Color', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: colorFilter,
                dropdownColor: AppColors.cardBackground,
                style: const TextStyle(color: Colors.white),
                onChanged: onColorChanged,
                items: [
                  const DropdownMenuItem(value: 'All', child: Text('All')),
                  const DropdownMenuItem(value: 'Red', child: Text('Red')),
                  const DropdownMenuItem(value: 'Blue', child: Text('Blue')),
                  const DropdownMenuItem(
                    value: 'Orange',
                    child: Text('Orange'),
                  ),
                  const DropdownMenuItem(value: 'Green', child: Text('Green')),
                  const DropdownMenuItem(
                    value: 'Purple',
                    child: Text('Purple'),
                  ),
                  const DropdownMenuItem(value: 'Grey', child: Text('Grey')),
                  const DropdownMenuItem(value: 'None', child: Text('None')),
                  const DropdownMenuItem(
                    value: 'Custom',
                    child: Text('Custom...'),
                  ),
                  if (colorFilter.startsWith('#'))
                    DropdownMenuItem(
                      value: colorFilter,
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: colorFromHex(colorFilter),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(colorFilter),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
