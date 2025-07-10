import 'package:shared_preferences/shared_preferences.dart';

class EvaluationSettingsService {
  EvaluationSettingsService._();
  static final EvaluationSettingsService _instance = EvaluationSettingsService._();
  factory EvaluationSettingsService() => _instance;
  static EvaluationSettingsService get instance => _instance;

  static const _thresholdKey = 'evaluation_ev_threshold';
  static const _icmKey = 'evaluation_use_icm';
  static const _endpointKey = 'evaluation_api_endpoint';
  static const _offlineKey = 'evaluation_offline_mode';

  double evThreshold = -0.01;
  bool useIcm = false;
  String remoteEndpoint = '';
  bool offline = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    evThreshold = prefs.getDouble(_thresholdKey) ?? -0.01;
    useIcm = prefs.getBool(_icmKey) ?? false;
    remoteEndpoint = prefs.getString(_endpointKey) ?? '';
    offline = prefs.getBool(_offlineKey) ?? false;
  }

  Future<void> update({double? threshold, bool? icm, String? endpoint, bool? offline}) async {
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
    if (offline != null) {
      this.offline = offline;
      await prefs.setBool(_offlineKey, offline);
    }
  }
}
