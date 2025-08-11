import 'package:shared_preferences/shared_preferences.dart';

import 'skill_tree_library_service.dart';

/// Item representing a single reward entry, optionally tied to a stage.
class RewardItem {
  final String id;
  final int? stageIndex;
  const RewardItem({required this.id, this.stageIndex});
}

/// Group of rewards belonging to a single track.
class TrackRewardGroup {
  final String trackId;
  final String trackTitle;
  final List<RewardItem> rewards;
  const TrackRewardGroup({
    required this.trackId,
    required this.trackTitle,
    required this.rewards,
  });
}

/// Builds a structured list of earned rewards grouped by track.
class RewardGalleryGroupByTrackService {
  RewardGalleryGroupByTrackService._();
  static final RewardGalleryGroupByTrackService instance =
      RewardGalleryGroupByTrackService._();

  /// Returns rewards grouped by track, optionally including stage-level info.
  Future<List<TrackRewardGroup>> getGroupedRewards() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final library = SkillTreeLibraryService.instance;
    if (library.getAllTracks().isEmpty) {
      await library.reload();
    }

    const prefix = 'reward_granted_';
    final Map<String, TrackRewardGroup> groups = {};

    for (final k in keys) {
      if (!k.startsWith(prefix) || !(prefs.getBool(k) ?? false)) {
        continue;
      }
      final id = k.substring(prefix.length);
      String trackId = id;
      int? stageIndex;
      if (id.contains('_stage_')) {
        final parts = id.split('_stage_');
        trackId = parts[0];
        stageIndex = int.tryParse(parts[1]);
      }
      final title = _resolveTrackTitle(library, trackId);
      final group = groups.putIfAbsent(
        trackId,
        () => TrackRewardGroup(trackId: trackId, trackTitle: title, rewards: []),
      );
      group.rewards.add(RewardItem(id: id, stageIndex: stageIndex));
    }

    final trackOrder = library.getAllTracks().map((t) => t.category).toList();
    final result = groups.values.toList();
    result.sort((a, b) {
      final ia = trackOrder.indexOf(a.trackId);
      final ib = trackOrder.indexOf(b.trackId);
      if (ia == -1 || ib == -1) {
        return a.trackTitle.compareTo(b.trackTitle);
      }
      return ia.compareTo(ib);
    });
    return result;
  }

  String _resolveTrackTitle(
      SkillTreeLibraryService library, String trackId) {
    final track = library.getTrack(trackId)?.tree;
    if (track == null) return trackId;
    if (track.roots.isNotEmpty) return track.roots.first.title;
    if (track.nodes.isNotEmpty) return track.nodes.values.first.title;
    return trackId;
  }
}

