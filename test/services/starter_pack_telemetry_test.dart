import 'package:poker_analyzer/services/starter_pack_telemetry.dart';
import 'package:test/test.dart';

void main() {
  test('starter import payload', () {
    final payload = starterImportPayload('p1', 2);
    expect(payload, {'packId': 'p1', 'version': 2});
  });

  test('starter banner payload', () {
    final payload = starterBannerPayload('p2', 10);
    expect(payload, {'packId': 'p2', 'spotCount': 10});
  });

  test('starter picker opened payload', () {
    final payload = starterPickerOpenedPayload();
    expect(payload, {});
  });

  test('starter picker selected payload', () {
    final payload = starterPickerSelectedPayload('p3', 15);
    expect(payload, {'packId': 'p3', 'spotCount': 15});
  });
}
