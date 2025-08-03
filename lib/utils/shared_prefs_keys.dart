/// Centralized SharedPreferences keys used across the app.
class SharedPrefsKeys {
  SharedPrefsKeys._();

  static String boosterInboxLast(String tag) => 'booster_inbox_last_$tag';
  static const String boosterInboxTotalDate = 'booster_inbox_total_date';
  static const String boosterInboxTotalCount = 'booster_inbox_total_count';

  static const String boosterOpenedPrefix = 'booster_opened_';
  static String boosterOpened(String tag) => '${boosterOpenedPrefix}$tag';

  static const String boosterDismissedPrefix = 'booster_dismissed_';
  static String boosterDismissed(String tag) => '${boosterDismissedPrefix}$tag';
}
