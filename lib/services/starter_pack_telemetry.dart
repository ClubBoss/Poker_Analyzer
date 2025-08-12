import 'analytics_service.dart';

Map<String, Object?> starterImportPayload(String packId, int version) => {
      'packId': packId,
      'version': version,
    };

Map<String, Object?> starterBannerPayload(String packId, int spotCount) => {
      'packId': packId,
      'spotCount': spotCount,
    };

class StarterPackTelemetry {
  const StarterPackTelemetry({AnalyticsService? analytics})
      : _analytics = analytics ?? AnalyticsService.instance;

  final AnalyticsService _analytics;

  Future<void> logImport(String event, String packId, int version) async {
    await _analytics.logEvent(event, starterImportPayload(packId, version));
  }

  Future<void> logBanner(String event, String packId, int spotCount) async {
    await _analytics.logEvent(
      event,
      starterBannerPayload(packId, spotCount),
    );
  }
}
