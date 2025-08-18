import 'booster_inbox_delivery_service.dart';
import 'inbox_booster_banner_service.dart';

/// Coordinates retrieval of deliverable boosters and surfaces them via a banner.
class InboxBoosterDeliveryController {
  final BoosterInboxDeliveryService delivery;
  final InboxBoosterBannerService banner;

  InboxBoosterDeliveryController({
    BoosterInboxDeliveryService? delivery,
    InboxBoosterBannerService? banner,
  }) : delivery = delivery ?? BoosterInboxDeliveryService.instance,
       banner = banner ?? InboxBoosterBannerService.instance;

  bool _triggered = false;
  bool _hasPending = false;

  /// Fetches the next deliverable tag and shows the inbox banner if available.
  Future<void> maybeTriggerBoosterInbox() async {
    if (_triggered) return;
    _triggered = true;
    final tag = await delivery.getNextDeliverableTag();
    if (tag != null) {
      _hasPending = true;
      await banner.show(tag);
      await delivery.markDelivered(tag);
    }
  }

  /// Returns true if a banner was triggered during this session.
  bool hasPendingInbox() => _hasPending;
}
