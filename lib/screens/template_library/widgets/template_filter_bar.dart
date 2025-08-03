import 'package:flutter/material.dart';

/// Search bar used for filtering templates in the library.
class TemplateFilterBar extends StatelessWidget {
  const TemplateFilterBar({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search templates',
          border: OutlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
