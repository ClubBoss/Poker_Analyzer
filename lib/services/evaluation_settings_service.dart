import 'package:shared_preferences/shared_preferences.dart';

class EvaluationSettingsService {
  EvaluationSettingsService._();
  static final EvaluationSettingsService _instance = EvaluationSettingsService._();
  factory EvaluationSettingsService() => _instance;
  static EvaluationSettingsService get instance => _instance;

  static const _thresholdKey = 'evaluation_ev_threshold';
  static const _icmKey = 'evaluation_use_icm';
  static const _endpointKey = 'evaluation_api_endpoint';

  double evThreshold = -0.01;
  bool useIcm = false;
  String remoteEndpoint = '';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    evThreshold = prefs.getDouble(_thresholdKey) ?? -0.01;
    useIcm = prefs.getBool(_icmKey) ?? false;
    remoteEndpoint = prefs.getString(_endpointKey) ?? '';
  }

  Future<void> update({double? threshold, bool? icm, String? endpoint}) async {
    final prefs = await SharedPreferences.getInstance();
    if (threshold != null) {
      evThreshold = threshold;
      await prefs.setDouble(_thresholdKey, threshold);
    }
    if (icm != null) {
      useIcm = icm;
      await prefs.setBool(_icmKey, icm);
    }
    if (endpoint != null) {
      remoteEndpoint = endpoint;
      await prefs.setString(_endpointKey, endpoint);
    }
  }
}
