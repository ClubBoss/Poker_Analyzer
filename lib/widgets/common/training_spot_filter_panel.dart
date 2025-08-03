import 'package:flutter/material.dart';

class TrainingSpotFilterPanel extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;

  const TrainingSpotFilterPanel({
    super.key,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Search by tag',
        ),
        onChanged: onSearchChanged,
      ),
    );
  }
}
