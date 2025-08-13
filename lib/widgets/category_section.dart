import 'package:flutter/material.dart';
import '../helpers/category_translations.dart';

class CategorySection extends StatelessWidget {
  final String title;
  final List<String> categories;
  final ValueChanged<String>? onTap;
  const CategorySection(
      {super.key, required this.title, required this.categories, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          for (final c in categories)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.category),
                  title: Text(translateCategory(c)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onTap?.call(c),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
