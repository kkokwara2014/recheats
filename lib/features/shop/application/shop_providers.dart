import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shop_repository.dart';
import '../domain/shop_fulfillment_settings.dart';

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return MockShopRepository();
});

final shopFulfillmentSettingsProvider =
    FutureProvider.autoDispose<ShopFulfillmentSettings>((ref) async {
  final result =
      await ref.watch(shopRepositoryProvider).fetchFulfillmentSettings();
  return result.when(
    success: (settings) => settings,
    failure: (error, stackTrace) => throw error,
  );
});

void invalidateShopFulfillmentSettings(WidgetRef ref) {
  ref.invalidate(shopFulfillmentSettingsProvider);
}
