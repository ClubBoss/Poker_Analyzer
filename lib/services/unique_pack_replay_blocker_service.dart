import 'package:shared_preferences/shared_preferences.dart';

import '../models/v2/training_pack_template_v2.dart';
import 'training_pack_fingerprint_generator.dart';
import 'training_session_fingerprint_recorder.dart';

/// Blocks replaying a training pack if it was already completed and
/// unique-session mode is enabled.
class UniquePackReplayBlockerService {
  UniquePackReplayBlockerService({
    SharedPreferences? prefs,
    TrainingPackFingerprintGenerator? fingerprintGenerator,
    TrainingSessionFingerprintRecorder? recorder,
  }) : _prefs = prefs,
       _fingerprintGenerator =
           fingerprintGenerator ?? const TrainingPackFingerprintGenerator(),
       _recorder = recorder ?? TrainingSessionFingerprintRecorder.instance;

  SharedPreferences? _prefs;
  final TrainingPackFingerprintGenerator _fingerprintGenerator;
  final TrainingSessionFingerprintRecorder _recorder;

  static const _flagKey = 'unique_pack_replay_blocking_enabled';

  Future<SharedPreferences> get _sp async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Enables or disables the unique session mode.
  Future<void> setBlockingEnabled(bool value) async {
    final prefs = await _sp;
    await prefs.setBool(_flagKey, value);
  }

  Future<bool> _isBlockingEnabled() async {
    final prefs = await _sp;
    return prefs.getBool(_flagKey) ?? false;
  }

  /// Returns `true` if replaying [pack] is blocked due to prior completion.
  Future<bool> isReplayBlocked(TrainingPackTemplateV2 pack) async {
    if (!await _isBlockingEnabled()) return false;
    final fp = _fingerprintGenerator.generateFromTemplate(pack);
    return _recorder.isCompleted(fp);
  }
}
