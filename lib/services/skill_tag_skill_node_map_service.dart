/// Provides mapping from skill tags to skill tree node IDs.
class SkillTagSkillNodeMapService {
  final Map<String, String> _map;

  const SkillTagSkillNodeMapService({Map<String, String>? map})
    : _map = map ?? const {};

  /// Returns the skill tree node ID for [tag], or null if not mapped.
  String? nodeIdForTag(String tag) => _map[tag.trim().toLowerCase()];
}
