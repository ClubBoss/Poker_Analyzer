import 'package:flutter/foundation.dart';

import 'template_storage_service.dart';
import 'training_pack_storage_service.dart';

class CategoryUsageService extends ChangeNotifier {
  final TemplateStorageService templates;
  final TrainingPackStorageService packs;

  List<String> _categories = [];
  List<String> get categories => List.unmodifiable(_categories);

  CategoryUsageService({required this.templates, required this.packs}) {
    templates.addListener(_recompute);
    packs.addListener(_recompute);
    _recompute();
  }

  void _recompute() {
    final counts = <String, int>{};
    for (final t in templates.templates) {
      final c =
          (t.category?.isNotEmpty == true) ? t.category! : 'Uncategorized';
      counts[c] = (counts[c] ?? 0) + 1;
    }
    for (final p in packs.packs) {
      final c = p.category.isNotEmpty ? p.category : 'Uncategorized';
      counts[c] = (counts[c] ?? 0) + 1;
    }
    final list = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    _categories = list;
    notifyListeners();
  }

  @override
  void dispose() {
    templates.removeListener(_recompute);
    packs.removeListener(_recompute);
    super.dispose();
  }
}
