
class UserProfilePreferenceService {
  UserProfilePreferenceService._();
  static final UserProfilePreferenceService instance =
      UserProfilePreferenceService._();

  static const _tagsKey = 'profile_pref_tags';
  static const _audKey = 'profile_pref_audiences';
  static const _diffKey = 'profile_pref_difficulties';

  Set<String> _preferredTags = {};
  Set<String> _preferredAudiences = {};
  Set<int> _preferredDifficulties = {};

  Future<void> load() async {
    final prefs = await PreferencesService.getInstance();
    _preferredTags = prefs.getStringList(_tagsKey)?.toSet() ?? {};
    _preferredAudiences = prefs.getStringList(_audKey)?.toSet() ?? {};
    _preferredDifficulties =
        prefs.getStringList(_diffKey)?.map(int.tryParse).whereType<int>().toSet() ?? {};
  }

  Set<String> get preferredTags => Set.unmodifiable(_preferredTags);
  Future<void> setPreferredTags(Set<String> tags) async {
    _preferredTags = tags.toSet();
    final prefs = await PreferencesService.getInstance();
    await prefs.setStringList(_tagsKey, _preferredTags.toList());
  }

  Set<String> get preferredAudiences => Set.unmodifiable(_preferredAudiences);
  Future<void> setPreferredAudiences(Set<String> audiences) async {
    _preferredAudiences = audiences.toSet();
    final prefs = await PreferencesService.getInstance();
    await prefs.setStringList(_audKey, _preferredAudiences.toList());
  }

  Set<int> get preferredDifficulties => Set.unmodifiable(_preferredDifficulties);
  Future<void> setPreferredDifficulties(Set<int> difficulties) async {
    _preferredDifficulties = difficulties.toSet();
    final prefs = await PreferencesService.getInstance();
    await prefs.setStringList(
        _diffKey, _preferredDifficulties.map((e) => e.toString()).toList());
  }
}
