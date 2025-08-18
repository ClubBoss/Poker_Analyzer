import 'package:flutter/material.dart';

class AllTagsScreen extends StatelessWidget {
  final List<String> tags;
  const AllTagsScreen({super.key, required this.tags});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Tags')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in tags)
                FilterChip(
                  label: Text(tag),
                  onSelected: (_) => Navigator.pop(context, tag),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
