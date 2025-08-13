/// Basic achievement model used by [AchievementsEngine].
class AchievementBasic {
  final String id;
  final String title;
  final String description;
  bool isUnlocked;
  DateTime? unlockDate;
  final int rewardXp;
  final int rewardCoins;
  final bool showRewardPopup;

  AchievementBasic({
    required this.id,
    required this.title,
    required this.description,
    this.isUnlocked = false,
    this.unlockDate,
    this.rewardXp = 0,
    this.rewardCoins = 0,
    this.showRewardPopup = true,
  });

  AchievementBasic copyWith({
    bool? isUnlocked,
    DateTime? unlockDate,
    int? rewardXp,
    int? rewardCoins,
    bool? showRewardPopup,
  }) {
    return AchievementBasic(
      id: id,
      title: title,
      description: description,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockDate: unlockDate ?? this.unlockDate,
      rewardXp: rewardXp ?? this.rewardXp,
      rewardCoins: rewardCoins ?? this.rewardCoins,
      showRewardPopup: showRewardPopup ?? this.showRewardPopup,
    );
  }
}
