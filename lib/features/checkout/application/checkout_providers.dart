import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/domain/saved_address.dart';
import '../../shop/domain/fulfillment_method.dart';
import '../../shop/domain/shop_fulfillment_settings.dart';
import '../domain/checkout_state.dart';
import '../domain/order_timing.dart';

final checkoutProvider =
    NotifierProvider<CheckoutNotifier, CheckoutState>(CheckoutNotifier.new);

class CheckoutNotifier extends Notifier<CheckoutState> {
  bool _seededAddress = false;

  @override
  CheckoutState build() => const CheckoutState();

  void syncWithSettings(ShopFulfillmentSettings settings) {
    final current = state.method;
    if (current != null && settings.supports(current)) return;
    final preferred = settings.preferredMethod;
    if (preferred == null) {
      state = state.copyWith(clearMethod: true);
    } else {
      state = state.copyWith(method: preferred);
    }
  }

  void seedAddressIfNeeded(List<SavedAddress> addresses) {
    if (_seededAddress || state.delivery.hasStreet || addresses.isEmpty) {
      return;
    }
    _seededAddress = true;
    SavedAddress preferred = addresses.first;
    for (final address in addresses) {
      if (address.isDefault) {
        preferred = address;
        break;
      }
    }
    applySavedAddress(preferred);
  }

  void selectMethod(FulfillmentMethod method) {
    state = state.copyWith(method: method);
  }

  void selectAsap() {
    state = state.copyWith(
      timing: state.timing.copyWith(
        mode: OrderTimingMode.asap,
        clearScheduledAt: true,
      ),
    );
  }

  void selectScheduled({DateTime? at}) {
    state = state.copyWith(
      timing: state.timing.copyWith(
        mode: OrderTimingMode.scheduled,
        scheduledAt: at,
        clearScheduledAt: at == null && state.timing.scheduledAt == null,
      ),
    );
  }

  void setScheduledAt(DateTime at) {
    state = state.copyWith(
      timing: state.timing.copyWith(
        mode: OrderTimingMode.scheduled,
        scheduledAt: at,
      ),
    );
  }

  void applySavedAddress(SavedAddress address) {
    state = state.copyWith(
      delivery: state.delivery.copyWith(
        savedAddressId: address.id,
        streetAddress: address.line1,
        apartmentUnit: address.line2 ?? '',
        city: address.city,
        state: address.state,
        zip: address.zip,
        instructions: address.instructions ?? '',
      ),
    );
  }

  void updateDelivery({
    String? streetAddress,
    String? apartmentUnit,
    String? city,
    String? stateCode,
    String? zip,
    String? instructions,
  }) {
    final editingCore = streetAddress != null ||
        apartmentUnit != null ||
        city != null ||
        stateCode != null ||
        zip != null;

    state = state.copyWith(
      delivery: state.delivery.copyWith(
        clearSavedAddressId: editingCore,
        streetAddress: streetAddress,
        apartmentUnit: apartmentUnit,
        city: city,
        state: stateCode,
        zip: zip,
        instructions: instructions,
      ),
    );
  }

  void reset() {
    _seededAddress = false;
    state = const CheckoutState();
  }
}
