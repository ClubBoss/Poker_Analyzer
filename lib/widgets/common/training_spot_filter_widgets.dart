import 'package:flutter/material.dart';

import '../../models/training_spot.dart';
import '../../theme/app_colors.dart';

class TagFilterSection extends StatelessWidget {
  final List<TrainingSpot> filtered;
  final Set<String> selectedTags;
  final bool expanded;
  final String? selectedPreset;
  final Map<String, List<String>> customPresets;
  final Map<String, List<String>> defaultPresets;
  final ValueChanged<bool> onExpanded;
  final void Function(String tag, bool selected) onTagToggle;
  final ValueChanged<String?> onPresetSelected;
  final VoidCallback onClearTags;
  final VoidCallback onOpenSelector;
  final VoidCallback onManagePresets;

  const TagFilterSection({
    super.key,
    required this.filtered,
    required this.selectedTags,
    required this.expanded,
    required this.selectedPreset,
    required this.customPresets,
    required this.defaultPresets,
    required this.onExpanded,
    required this.onTagToggle,
    required this.onPresetSelected,
    required this.onClearTags,
    required this.onOpenSelector,
    required this.onManagePresets,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExpansionTile(
          title: const Text(
            'Фильтры тегов',
            style: TextStyle(color: Colors.white),
          ),
          initiallyExpanded: expanded,
          onExpansionChanged: onExpanded,
          iconColor: Colors.white,
          collapsedIconColor: Colors.white,
          collapsedTextColor: Colors.white,
          textColor: Colors.white,
          childrenPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          children: [
            _buildTagFilters(),
            const SizedBox(height: 8),
            _buildPresetDropdown(),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: onClearTags,
                child: const Text('Сбросить теги'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildTagFilterRow(),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            onPressed: onManagePresets,
            child: const Text('Редактировать пресеты'),
          ),
        ),
      ],
    );
  }

  Widget _buildTagFilterRow() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final tag in selectedTags)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: FilterChip(
                label: Text(tag),
                selected: true,
                onSelected: (selected) => onTagToggle(tag, selected),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTagFilters() {
    final count = selectedTags.length;
    final label =
        count == 0 ? 'Выбрать теги' : 'Выбрано: $count';
    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton(
        onPressed: onOpenSelector,
        child: Text(label),
      ),
    );
  }

  Widget _buildPresetDropdown() {
    return Row(
      children: [
        const Text('Применить теги ко всем',
            style: TextStyle(color: Colors.white)),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: selectedPreset,
          hint: const Text('Выбрать', style: TextStyle(color: Colors.white60)),
          dropdownColor: AppColors.cardBackground,
          style: const TextStyle(color: Colors.white),
          items: [
            for (final entry in defaultPresets.entries)
              DropdownMenuItem(
                value: entry.key,
                child: Text(entry.key),
              ),
            for (final entry in customPresets.entries)
              DropdownMenuItem(
                value: entry.key,
                child: Text(entry.key),
              ),
          ],
          onChanged: onPresetSelected,
        ),
      ],
    );
  }
}

class DifficultyChipRow extends StatelessWidget {
  final Set<int> selected;
  final ValueChanged<int> onChanged;
  final VoidCallback onToggleAll;

  const DifficultyChipRow({
    required this.selected,
    required this.onChanged,
    required this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Сложность', style: TextStyle(color: Colors.white)),
        const SizedBox(width: 8),
        Wrap(
          spacing: 4,
          children: [
            for (int i = 1; i <= 5; i++)
              FilterChip(
                label: Text('$i'),
                selected: selected.contains(i),
                onSelected: (_) => onChanged(i),
              ),
          ],
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onToggleAll,
          child: const Text('Выбрать все'),
        ),
      ],
    );
  }
}


class RatingChipRow extends StatelessWidget {
  final Set<int> selected;
  final ValueChanged<int> onChanged;
  final VoidCallback onToggleAll;

  const RatingChipRow({
    required this.selected,
    required this.onChanged,
    required this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Рейтинг', style: TextStyle(color: Colors.white)),
        const SizedBox(width: 8),
        Wrap(
          spacing: 4,
          children: [
            for (int i = 1; i <= 5; i++)
              FilterChip(
                label: Text('$i'),
                selected: selected.contains(i),
                onSelected: (_) => onChanged(i),
              ),
          ],
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onToggleAll,
          child: const Text('Выбрать все'),
        ),
      ],
    );
  }
}

class FilterBar extends StatelessWidget {
  final Set<String> selectedTags;
  final void Function(String tag, bool selected) onTagToggle;
  final Set<int> difficultyFilters;
  final ValueChanged<int> onDifficultyChanged;
  final VoidCallback onDifficultyToggleAll;
  final Set<int> ratingFilters;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onRatingToggleAll;

  const FilterBar({
    required this.selectedTags,
    required this.onTagToggle,
    required this.difficultyFilters,
    required this.onDifficultyChanged,
    required this.onDifficultyToggleAll,
    required this.ratingFilters,
    required this.onRatingChanged,
    required this.onRatingToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final tag in selectedTags)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: FilterChip(
                      label: Text(tag),
                      selected: true,
                      onSelected: (selected) => onTagToggle(tag, selected),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          DifficultyChipRow(
            selected: difficultyFilters,
            onChanged: onDifficultyChanged,
            onToggleAll: onDifficultyToggleAll,
          ),
          const SizedBox(height: 8),
          RatingChipRow(
            selected: ratingFilters,
            onChanged: onRatingChanged,
            onToggleAll: onRatingToggleAll,
          ),
        ],
      ),
    );
  }
}

class SliverFilterBarDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  SliverFilterBarDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant SliverFilterBarDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}

class SliverSortHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  SliverSortHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant SliverSortHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}

class ApplyDifficultyDropdown extends StatelessWidget {
  final ValueChanged<int?> onChanged;

  const ApplyDifficultyDropdown({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Применить сложность ко всем',
            style: TextStyle(color: Colors.white)),
        const SizedBox(width: 8),
        DropdownButton<int?>(
          hint: const Text('Выбрать', style: TextStyle(color: Colors.white60)),
          dropdownColor: AppColors.cardBackground,
          style: const TextStyle(color: Colors.white),
          items: [
            for (int i = 1; i <= 5; i++)
              DropdownMenuItem(value: i, child: Text('$i')),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class ApplyRatingDropdown extends StatelessWidget {
  final ValueChanged<int?> onChanged;

  const ApplyRatingDropdown({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Применить рейтинг ко всем',
            style: TextStyle(color: Colors.white)),
        const SizedBox(width: 8),
        DropdownButton<int?>(
          hint: const Text('Выбрать', style: TextStyle(color: Colors.white60)),
          dropdownColor: AppColors.cardBackground,
          style: const TextStyle(color: Colors.white),
          items: [
            for (int i = 1; i <= 5; i++)
              DropdownMenuItem(value: i, child: Text('$i')),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class SortDropdown extends StatelessWidget {
  final SortOption? sortOption;
  final List<TrainingSpot> filtered;
  final bool manualOrder;
  final void Function(SortOption? value, List<TrainingSpot> spots) onChanged;

  const SortDropdown({
    required this.sortOption,
    required this.filtered,
    required this.manualOrder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<SortOption?>(
      value: sortOption,
      hint: const Text('Сортировать', style: TextStyle(color: Colors.white60)),
      dropdownColor: AppColors.cardBackground,
      style: const TextStyle(color: Colors.white),
      items: const [
        DropdownMenuItem(
          value: null,
          child: Text('Сбросить сортировку'),
        ),
        DropdownMenuItem(
          value: SortOption.buyInAsc,
          child: Text('Buy-In ↑'),
        ),
        DropdownMenuItem(
          value: SortOption.buyInDesc,
          child: Text('Buy-In ↓'),
        ),
        DropdownMenuItem(
          value: SortOption.gameType,
          child: Text('Тип игры'),
        ),
        DropdownMenuItem(
          value: SortOption.tournamentId,
          child: Text('ID турнира'),
        ),
        DropdownMenuItem(
          value: SortOption.difficultyAsc,
          child: Text('Сложность (по возрастанию)'),
        ),
        DropdownMenuItem(
          value: SortOption.difficultyDesc,
          child: Text('Сложность (по убыванию)'),
        ),
      ],
      onChanged:
          manualOrder ? null : (value) => onChanged(value, filtered),
    );
  }
}

class ListSortDropdown extends StatelessWidget {
  final ListSortOption? value;
  final List<TrainingSpot> filtered;
  final bool manualOrder;
  final void Function(ListSortOption? value, List<TrainingSpot> spots) onChanged;

  const ListSortDropdown({
    required this.value,
    required this.filtered,
    required this.manualOrder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Сортировка', style: TextStyle(color: Colors.white)),
        const SizedBox(width: 8),
        DropdownButton<ListSortOption?>(
          value: value,
          hint:
              const Text('Без сортировки', style: TextStyle(color: Colors.white60)),
          dropdownColor: AppColors.cardBackground,
          style: const TextStyle(color: Colors.white),
          items: const [
            DropdownMenuItem(value: null, child: Text('Без сортировки')),
            DropdownMenuItem(
                value: ListSortOption.dateNew,
                child: Text('Дата добавления (новые)')),
            DropdownMenuItem(
                value: ListSortOption.dateOld,
                child: Text('Дата добавления (старые)')),
            DropdownMenuItem(
                value: ListSortOption.rating, child: Text('Рейтинг')),
            DropdownMenuItem(
                value: ListSortOption.difficulty, child: Text('Сложность')),
            DropdownMenuItem(
                value: ListSortOption.comment, child: Text('Комментарий')),
          ],
          onChanged: manualOrder ? null : (v) => onChanged(v, filtered),
        ),
      ],
    );
  }
}

class RatingSortDropdown extends StatelessWidget {
  final RatingSortOrder? order;
  final List<TrainingSpot> filtered;
  final bool manualOrder;
  final void Function(RatingSortOrder? value, List<TrainingSpot> spots)
      onChanged;

  const RatingSortDropdown({
    required this.order,
    required this.filtered,
    required this.manualOrder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Сортировать по рейтингу',
            style: TextStyle(color: Colors.white)),
        const SizedBox(width: 8),
        DropdownButton<RatingSortOrder?>(
          value: order,
          hint:
              const Text('Без сортировки', style: TextStyle(color: Colors.white60)),
          dropdownColor: AppColors.cardBackground,
          style: const TextStyle(color: Colors.white),
          items: const [
            DropdownMenuItem(
              value: null,
              child: Text('Без сортировки'),
            ),
            DropdownMenuItem(
              value: RatingSortOrder.highFirst,
              child: Text('Сначала высокий'),
            ),
            DropdownMenuItem(
              value: RatingSortOrder.lowFirst,
              child: Text('Сначала низкий'),
            ),
          ],
          onChanged: manualOrder ? null : (v) => onChanged(v, filtered),
        ),
      ],
    );
  }
}

class QuickSortSegment extends StatelessWidget {
  final QuickSortOption? value;
  final ValueChanged<QuickSortOption> onChanged;

  const QuickSortSegment({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Сортировать по', style: TextStyle(color: Colors.white)),
        const SizedBox(height: 4),
        ToggleButtons(
          isSelected: QuickSortOption.values
              .map((e) => e == value)
              .toList(),
          onPressed: (i) => onChanged(QuickSortOption.values[i]),
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('ID'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('Сложность'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('Рейтинг'),
            ),
          ],
        ),
      ],
    );
  }
}

class SimpleSortRow extends StatelessWidget {
  final SimpleSortField? field;
  final SimpleSortOrder order;
  final ValueChanged<SimpleSortField?> onFieldChanged;
  final ValueChanged<SimpleSortOrder> onOrderChanged;

  const SimpleSortRow({
    required this.field,
    required this.order,
    required this.onFieldChanged,
    required this.onOrderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DropdownButton<SimpleSortField?>(
          value: field,
          hint: const Text('Сортировать по',
              style: TextStyle(color: Colors.white60)),
          dropdownColor: AppColors.cardBackground,
          style: const TextStyle(color: Colors.white),
          items: const [
            DropdownMenuItem(value: null, child: Text('Без сортировки')),
            DropdownMenuItem(
                value: SimpleSortField.createdAt, child: Text('Дата')),
            DropdownMenuItem(
                value: SimpleSortField.difficulty, child: Text('Сложность')),
            DropdownMenuItem(
                value: SimpleSortField.rating, child: Text('Рейтинг')),
          ],
          onChanged: onFieldChanged,
        ),
        const SizedBox(width: 8),
        DropdownButton<SimpleSortOrder>(
          value: order,
          dropdownColor: AppColors.cardBackground,
          style: const TextStyle(color: Colors.white),
          items: const [
            DropdownMenuItem(
                value: SimpleSortOrder.ascending,
                child: Text('По возрастанию')),
            DropdownMenuItem(
                value: SimpleSortOrder.descending,
                child: Text('По убыванию')),
          ],
          onChanged: (v) => onOrderChanged(v!),
        ),
      ],
    );
  }
}

class SelectionActions extends StatelessWidget {
  final int selectedCount;
  final List<TrainingSpot> filtered;
  final void Function(List<TrainingSpot> spots) onSelectAll;
  final VoidCallback onClearSelection;
  final VoidCallback onDeleteSelected;
  final VoidCallback onExportSelected;
  final VoidCallback onEditTags;

  const SelectionActions({
    required this.selectedCount,
    required this.filtered,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onDeleteSelected,
    required this.onExportSelected,
    required this.onEditTags,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () => onSelectAll(filtered),
            child: const Text('Выделить все'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: selectedCount == 0 ? null : onClearSelection,
            child: const Text('Снять выделение'),
          ),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              ElevatedButton(
                onPressed: selectedCount == 0 ? null : onDeleteSelected,
                child: const Text('Удалить выбранные'),
              ),
              if (selectedCount > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$selectedCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: selectedCount == 0 ? null : onExportSelected,
            child: const Text('Экспортировать выбранные'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: selectedCount == 0 ? null : onEditTags,
            icon: const Icon(Icons.label_outline),
            label: const Text('Метки'),
          ),
        ],
      ),
    );
  }
}

class BatchFilterActions extends StatelessWidget {
  final bool disabled;
  final VoidCallback onApply;
  final VoidCallback onDelete;

  const BatchFilterActions({
    required this.disabled,
    required this.onApply,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: disabled ? null : onApply,
            child: const Text('Применить фильтры ко всем'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: disabled ? null : onDelete,
            child: const Text('Удалить все отфильтрованные'),
          ),
        ],
      ),
    );
  }
}

class QuickPresetRow extends StatelessWidget {
  final String? active;
  final Map<String, String> presets;
  final ValueChanged<String?> onChanged;

  const QuickPresetRow({
    super.key,
    required this.active,
    required this.presets,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final entry in presets.entries)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ChoiceChip(
                label: Text(entry.key),
                selected: active == entry.key,
                onSelected: (selected) =>
                    onChanged(selected ? entry.key : null),
              ),
            ),
        ],
      ),
    );
  }
}

class PulsingIndicator extends StatefulWidget {
  const _PulsingIndicator();

  @override
  State<PulsingIndicator> createState() => PulsingIndicatorState();
}

class PulsingIndicatorState extends State<PulsingIndicator> {
  bool _fadeIn = true;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _fadeIn ? 1.0 : 0.4, end: _fadeIn ? 0.4 : 1.0),
      duration: const Duration(seconds: 1),
      onEnd: () => setState(() => _fadeIn = !_fadeIn),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: const Icon(Icons.circle, size: 8, color: Colors.red),
    );
  }
}
