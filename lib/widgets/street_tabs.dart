// lib/widgets/street_tabs.dart
import 'package:flutter/material.dart';

import '../helpers/poker_street_helper.dart';

class StreetTabs extends StatelessWidget {
  final int currentStreet;
  final Function(int) onStreetChanged;

  const StreetTabs({
    super.key,
    required this.currentStreet,
    required this.onStreetChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          kStreetNames.length,
          (index) => _buildTab(streetName(index), index),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final bool isSelected = currentStreet == index;
    return GestureDetector(
      onTap: () => onStreetChanged(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
