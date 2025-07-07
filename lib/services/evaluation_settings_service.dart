import 'package:shared_preferences/shared_preferences.dart';

class EvaluationSettingsService {
  EvaluationSettingsService._();
  static final EvaluationSettingsService _instance = EvaluationSettingsService._();
  factory EvaluationSettingsService() => _instance;
  static EvaluationSettingsService get instance => _instance;

  static const _thresholdKey = 'evaluation_ev_threshold';
  static const _icmKey = 'evaluation_use_icm';

  double evThreshold = -0.01;
  bool useIcm = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    evThreshold = prefs.getDouble(_thresholdKey) ?? -0.01;
    useIcm = prefs.getBool(_icmKey) ?? false;
  }

  Future<void> update({double? threshold, bool? icm}) async {
    final prefs = await SharedPreferences.getInstance();
    if (threshold != null) {
      evThreshold = threshold;
      await prefs.setDouble(_thresholdKey, threshold);
    }
    if (icm != null) {
      useIcm = icm;
      await prefs.setBool(_icmKey, icm);
    }
  }
}
