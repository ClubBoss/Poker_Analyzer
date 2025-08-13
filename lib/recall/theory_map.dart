class TheoryMap {
  static const Map<String, String> _openFoldPosition = {
    'position:EP': 'open_fold_ep_ranges',
    'position:MP': 'open_fold_mp_ranges',
    'position:CO': 'open_fold_co_ranges',
    'position:BTN': 'open_fold_btn_ranges',
    'position:SB': 'open_fold_sb_ranges',
  };

  static const Map<String, String> _threeBetPushStack = {
    'stack:10-15': '3bp_10_15_bb',
    'stack:15-20': '3bp_15_20_bb',
    'stack:20-25': '3bp_20_25_bb',
    'stack:25-30': '3bp_25_30_bb',
  };

  static String? idFor(Iterable<String> tags) {
    final t = tags.map((e) => e.toLowerCase()).toSet();
    if (t.contains('open_fold')) {
      for (final entry in _openFoldPosition.entries) {
        if (t.contains(entry.key)) return entry.value;
      }
      return 'open_fold_overview';
    }
    if (t.contains('3bet_push')) {
      for (final entry in _threeBetPushStack.entries) {
        if (t.contains(entry.key)) return entry.value;
      }
      return '3bp_overview';
    }
    return null;
  }
}
