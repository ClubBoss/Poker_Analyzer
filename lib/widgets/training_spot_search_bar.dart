import 'package:flutter/material.dart';

class TrainingSpotSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const TrainingSpotSearchBar(
      {super.key, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(hintText: 'Search'),
        onChanged: onChanged,
      ),
    );
  }
}
