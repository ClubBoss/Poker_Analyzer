import '../models/stage_id.dart';

/// Maps weakness tags to relevant learning path stages.
class WeaknessTagResolver {
  const WeaknessTagResolver();

  static final Map<String, List<StageID>> _tagToStageMap = {
    'sbvsbb': [
      StageID('push_fold_cash_stage', tags: ['sb', 'pushfold', 'cash']),
    ],
    '3betpot': [
      StageID(
        '3bet_push_sb_vs_btn_stage',
        tags: ['sb', 'btn', '3bet-push', 'mtt'],
      ),
      StageID(
        '3bet_push_co_vs_btn_stage',
        tags: ['co', 'btn', '3bet-push', 'mtt'],
      ),
    ],
    'openfold': [
      StageID('open_fold_lj_mtt_stage', tags: ['lj', 'openfold', 'mtt']),
      StageID('open_fold_utg_mtt_stage', tags: ['utg', 'openfold', 'mtt']),
    ],
  };

  /// Returns stages relevant to the given [tag].
  /// If no mapping exists, returns an empty list.
  List<StageID> resolveRelevantStages(String tag) {
    final key = tag.trim().toLowerCase();
    return _tagToStageMap[key] ?? const [];
  }
}
