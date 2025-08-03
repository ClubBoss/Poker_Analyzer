
class EvaluationSettingsService {
  EvaluationSettingsService._();
  static final EvaluationSettingsService _instance = EvaluationSettingsService._();
  factory EvaluationSettingsService() => _instance;
  static EvaluationSettingsService get instance => _instance;

  static const _thresholdKey = 'evaluation_ev_threshold';
  static const _icmKey = 'evaluation_use_icm';
  static const _endpointKey = 'evaluation_api_endpoint';
  static const _offlineKey = 'evaluation_offline_mode';
  static const _payoutsKey = 'evaluation_icm_payouts';

  double evThreshold = -0.01;
  bool useIcm = false;
  String remoteEndpoint = '';
  bool offline = false;
  List<double> payouts = const [0.5, 0.3, 0.2];

  Future<void> load() async {
    final prefs = await PreferencesService.getInstance();
    evThreshold = prefs.getDouble(_thresholdKey) ?? -0.01;
    useIcm = prefs.getBool(_icmKey) ?? false;
    remoteEndpoint = prefs.getString(_endpointKey) ?? '';
    offline = prefs.getBool(_offlineKey) ?? false;
    final p = prefs.getString(_payoutsKey);
    if (p != null && p.isNotEmpty) {
      payouts = p.split(',').map(double.parse).toList();
    }
  }

  Future<void> update({double? threshold, bool? icm, String? endpoint, bool? offline, List<double>? payouts}) async {
    final prefs = await PreferencesService.getInstance();
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
    if (payouts != null) {
      this.payouts = payouts;
      await prefs.setString(_payoutsKey, payouts.join(','));
    }
  }
}
