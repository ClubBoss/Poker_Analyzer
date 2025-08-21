import 'package:flutter/material.dart';

enum LevelStage { bronze, silver, gold, platinum, diamond }

extension LevelStageX on LevelStage {
  String get label =>
      ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond'][index];
  Color get color => const [
        Color(0xffcd7f32),
        Color(0xffc0c0c0),
        Color(0xffffd700),
        Color(0xffe5e4e2),
        Color(0xffb9f2ff),
      ][index];
}

LevelStage stageForLevel(int level) {
  if (level >= 21) return LevelStage.diamond;
  if (level >= 16) return LevelStage.platinum;
  if (level >= 11) return LevelStage.gold;
  if (level >= 6) return LevelStage.silver;
  return LevelStage.bronze;
}
