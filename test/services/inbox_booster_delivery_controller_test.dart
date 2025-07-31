import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/inbox_booster_delivery_controller.dart';
import 'package:poker_analyzer/services/booster_inbox_delivery_service.dart';
import 'package:poker_analyzer/services/inbox_booster_banner_service.dart';

class _FakeDeliveryService extends BoosterInboxDeliveryService {
  String? tag;
  _FakeDeliveryService(this.tag) : super();

  @override
  Future<String?> getNextDeliverableTag({int maxCandidates = 5}) async {
    return tag;
  }

  @override
  Future<void> markDelivered(String tag) async {
    this.tag = null;
  }
}

class _FakeBannerService extends InboxBoosterBannerService {
  _FakeBannerService() : super();

  @override
  Future<void> show(String tag) async {
    lastShownTag = tag;
  }

  String? lastShownTag;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('triggers banner once per session', () async {
    final delivery = _FakeDeliveryService('a');
    final banner = _FakeBannerService();
    final controller = InboxBoosterDeliveryController(
      delivery: delivery,
      banner: banner,
    );

    await controller.maybeTriggerBoosterInbox();
    expect(banner.lastShownTag, 'a');
    expect(controller.hasPendingInbox(), isTrue);

    banner.lastShownTag = null;
    await controller.maybeTriggerBoosterInbox();
    expect(banner.lastShownTag, isNull);
  });
}
