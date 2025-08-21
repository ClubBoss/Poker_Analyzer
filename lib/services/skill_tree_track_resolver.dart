import 'skill_tree_library_service.dart';

/// Resolves the track id for a given skill tree node.
class SkillTreeTrackResolver {
  SkillTreeTrackResolver({SkillTreeLibraryService? library})
      : _library = library ?? SkillTreeLibraryService.instance;

  final SkillTreeLibraryService _library;

  static SkillTreeTrackResolver instance = SkillTreeTrackResolver();

  Future<void> _ensureLoaded() async {
    if (_library.getAllNodes().isEmpty) {
      await _library.reload();
    }
  }

  /// Returns the track id that contains [nodeId], or `null` if not found.
  Future<String?> getTrackIdForNode(String nodeId) async {
    if (nodeId.isEmpty) return null;
    await _ensureLoaded();
    for (final node in _library.getAllNodes()) {
      if (node.id == nodeId) return node.category;
    }
    return null;
  }
}
