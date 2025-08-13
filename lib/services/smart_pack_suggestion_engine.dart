import 'package:shared_preferences/shared_preferences.dart';

import '../models/v2/training_pack_template_v2.dart';
import 'pack_library_loader_service.dart';

class UserProfile {
  final String? audience;
  final List<String> recentTags;
  final List<String> weakTags;
  const UserProfile(
      {this.audience, this.recentTags = const [], this.weakTags = const []});
}

class SmartPackSuggestionEngine {
  const SmartPackSuggestionEngine();

  Future<List<TrainingPackTemplateV2>> suggestTopPacks(
    UserProfile profile, {
    int limit = 3,
  }) async {
    await PackLibraryLoaderService.instance.loadLibrary();
    final prefs = await SharedPreferences.getInstance();
    final entries = <MapEntry<TrainingPackTemplateV2, double>>[];
    for (final t in PackLibraryLoaderService.instance.library) {
      if (prefs.getBool('completed_tpl_${t.id}') ?? false) continue;
      if (profile.audience != null &&
          t.audience != null &&
          t.audience!.isNotEmpty &&
          profile.audience != t.audience) {
        continue;
      }
      var score = (t.meta['rankScore'] as num?)?.toDouble() ?? 0;
      if (profile.recentTags.any(t.tags.contains)) score += 1;
      if (profile.weakTags.any(t.tags.contains)) score += 1;
      entries.add(MapEntry(t, score));
    }
    entries.sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in entries.take(limit)) e.key];
  }
}
