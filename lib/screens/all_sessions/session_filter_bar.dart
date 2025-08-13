import 'package:flutter/material.dart';

class SessionFilterBar extends StatelessWidget {
  final String filter;
  final ValueChanged<String?> onFilterChanged;
  final Set<String> packNames;
  final VoidCallback onPickDateRange;
  final String dateFilterText;
  final String sortMode;
  final ValueChanged<String?> onSortChanged;
  final VoidCallback onReset;

  const SessionFilterBar({
    super.key,
    required this.filter,
    required this.onFilterChanged,
    required this.packNames,
    required this.onPickDateRange,
    required this.dateFilterText,
    required this.sortMode,
    required this.onSortChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButton<String>(
            value: filter,
            dropdownColor: const Color(0xFF2A2B2E),
            style: const TextStyle(color: Colors.white),
            onChanged: onFilterChanged,
            items: [
              const DropdownMenuItem(
                value: 'all',
                child: Text('Все сессии'),
              ),
              const DropdownMenuItem(
                value: 'success',
                child: Text('Только успешные (>70%)'),
              ),
              const DropdownMenuItem(
                value: 'fail',
                child: Text('Только неуспешные (<70%)'),
              ),
              if (packNames.length > 1) ...[
                for (final name in packNames)
                  DropdownMenuItem(
                    value: 'pack:$name',
                    child: Text('Пакет: $name'),
                  )
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: onPickDateRange,
          child: Text(dateFilterText),
        ),
        const SizedBox(width: 8),
        const Text('Сортировка:', style: TextStyle(color: Colors.white)),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: sortMode,
          dropdownColor: const Color(0xFF2A2B2E),
          style: const TextStyle(color: Colors.white),
          onChanged: onSortChanged,
          items: const [
            DropdownMenuItem(
              value: 'date_desc',
              child: Text('по дате (новые)'),
            ),
            DropdownMenuItem(
              value: 'date_asc',
              child: Text('по дате (старые)'),
            ),
            DropdownMenuItem(
              value: 'accuracy_desc',
              child: Text('по точности (высокая)'),
            ),
            DropdownMenuItem(
              value: 'accuracy_asc',
              child: Text('по точности (низкая)'),
            ),
          ],
        ),
        IconButton(
          onPressed: onReset,
          icon: const Icon(Icons.clear),
          tooltip: 'Сбросить',
        )
      ],
    );
  }
}
