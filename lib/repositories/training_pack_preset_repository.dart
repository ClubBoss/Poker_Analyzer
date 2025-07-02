import "../models/v2/hero_position.dart";
import '../models/v2/training_pack_preset.dart';

class TrainingPackPresetRepository {
  static Future<List<TrainingPackPreset>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      TrainingPackPreset(id: '1', name: 'Push/Fold SB', heroBbStack: 10, playerStacksBb: const [10, 10], heroPos: HeroPosition.sb, spotCount: 20, bbCallPct: 20),
      TrainingPackPreset(id: '2', name: 'Push/Fold BTN', heroBbStack: 15, playerStacksBb: const [15, 15, 15], heroPos: HeroPosition.btn, spotCount: 20, bbCallPct: 20),
    ];
  }
}
