import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/v2/training_pack_template_v2.dart';

class PackLibraryLoaderService {
  PackLibraryLoaderService._();
  static final instance = PackLibraryLoaderService._();

  List<TrainingPackTemplateV2>? _cache;

  Future<List<TrainingPackTemplateV2>> loadLibrary() async {
    final cached = _cache;
    if (cached != null) return cached;
    try {
      final raw =
          await rootBundle.loadString('assets/packs/v2/library_index.json');
      final data = jsonDecode(raw);
      if (data is List) {
        _cache = [
          for (final item in data)
            if (item is Map)
              TrainingPackTemplateV2.fromJson(
                  Map<String, dynamic>.from(item as Map))
        ];
        return _cache!;
      }
    } catch (_) {}
    _cache = [];
    return const [];
  }

  List<TrainingPackTemplateV2> get library => List.unmodifiable(_cache ?? []);
}
