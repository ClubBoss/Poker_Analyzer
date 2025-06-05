// Файл #6: street_actions_widget.dart
// Назначение: Переключение улиц (Preflop / Flop / Turn / River)
// В данной версии:
// - Устойчивые стили кнопок
// - Подсветка активной улицы

import 'package:flutter/material.dart';

class StreetActionsWidget extends StatelessWidget {
  final int currentStreet;
  final Function(int) onStreetChanged;

  const StreetActionsWidget({
    Key? key,
    required this.currentStreet,
    required this.onStreetChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> streets = ['Префлоп', 'Флоп', 'Тёрн', 'Ривер'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(streets.length, (index) {
          final isSelected = index == currentStreet;
          return ElevatedButton(
            onPressed: () => onStreetChanged(index),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? Colors.amber : Colors.grey[800],
              foregroundColor: isSelected ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              streets[index],
              style: const TextStyle(fontSize: 16),
            ),
          );
        }),
      ),
    );
  }
}
