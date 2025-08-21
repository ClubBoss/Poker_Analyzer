import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:poker_analyzer/services/offline_evaluator_service.dart';
import 'package:poker_analyzer/services/push_fold_ev_service.dart';
import 'package:poker_analyzer/services/remote_ev_service.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';

class _TestPathProvider extends PathProviderPlatform {
  _TestPathProvider(this.path);
  final String path;
  @override
  Future<String?> getTemporaryPath() async => path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
  @override
  Future<String?> getLibraryPath() async => path;
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
  @override
  Future<String?> getApplicationCachePath() async => path;
  @override
  Future<String?> getExternalStoragePath() async => path;
  @override
  Future<List<String>?> getExternalCachePaths() async => [path];
  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async =>
      [path];
  @override
  Future<String?> getDownloadsPath() async => path;
}

void _apply(TrainingPackSpot spot, {double? ev, double? icm}) {
  final hero = spot.hand.heroIndex;
  final acts = spot.hand.actions[0] ?? [];
  for (var i = 0; i < acts.length; i++) {
    final a = acts[i];
    if (a.playerIndex == hero && a.action == 'push') {
      acts[i] = a.copyWith(ev: ev ?? a.ev, icmEv: icm ?? a.icmEv);
      break;
    }
  }
}

class _MockRemoteEvService extends RemoteEvService {
  _MockRemoteEvService({this.ev, this.icm}) : super(endpoint: '');
  int evalCalls = 0;
  int icmCalls = 0;
  final double? ev;
  final double? icm;
  @override
  Future<void> evaluate(TrainingPackSpot spot, {int anteBb = 0}) async {
    evalCalls++;
    _apply(spot, ev: ev);
  }

  @override
  Future<void> evaluateIcm(TrainingPackSpot spot, {int anteBb = 0}) async {
    icmCalls++;
    _apply(spot, ev: ev, icm: icm);
  }
}

TrainingPackSpot _spot(String id) => TrainingPackSpot(
      id: id,
      hand: HandData.fromSimpleInput('AA', HeroPosition.sb, 10),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('evaluate offline uses push ev', () async {
    final dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _TestPathProvider(dir.path);
    SharedPreferences.setMockInitialValues({});
    OfflineEvaluatorService.isOffline = true;
    final remote = _MockRemoteEvService();
    final service = OfflineEvaluatorService(remote: remote);
    final spot = _spot('a');
    await service.evaluate(spot);
    final ev = computePushEV(
      heroBbStack: 10,
      bbCount: 1,
      heroHand: 'AA',
      anteBb: 0,
    );
    expect(spot.heroEv, ev);
    expect(remote.evalCalls, 0);
    await dir.delete(recursive: true);
  });

  test('evaluateIcm offline uses push ev and icm', () async {
    final dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _TestPathProvider(dir.path);
    SharedPreferences.setMockInitialValues({});
    OfflineEvaluatorService.isOffline = true;
    final remote = _MockRemoteEvService();
    final service = OfflineEvaluatorService(remote: remote);
    final spot = _spot('b');
    await service.evaluateIcm(spot);
    final ev = computePushEV(
      heroBbStack: 10,
      bbCount: 1,
      heroHand: 'AA',
      anteBb: 0,
    );
    final icm = computeIcmPushEV(
      chipStacksBb: [10, 10],
      heroIndex: 0,
      heroHand: 'AA',
      chipPushEv: ev,
    );
    expect(spot.heroEv, ev);
    expect(spot.heroIcmEv, icm);
    expect(remote.icmCalls, 0);
    await dir.delete(recursive: true);
  });

  test('cached remote values reused when offline', () async {
    final dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _TestPathProvider(dir.path);
    SharedPreferences.setMockInitialValues({});
    final remote = _MockRemoteEvService(ev: 1.2, icm: 2.3);
    OfflineEvaluatorService.isOffline = false;
    final service = OfflineEvaluatorService(remote: remote);
    final spot1 = _spot('c');
    await service.evaluateIcm(spot1);
    expect(remote.icmCalls, 1);
    expect(spot1.heroEv, 1.2);
    expect(spot1.heroIcmEv, 2.3);
    OfflineEvaluatorService.isOffline = true;
    final spot2 = _spot('c');
    await OfflineEvaluatorService(remote: remote).evaluateIcm(spot2);
    expect(spot2.heroEv, 1.2);
    expect(spot2.heroIcmEv, 2.3);
    expect(remote.icmCalls, 1);
    await dir.delete(recursive: true);
  });
}
