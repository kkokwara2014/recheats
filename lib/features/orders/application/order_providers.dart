import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/firebase/firebase_bootstrap.dart';
import '../data/order_repository.dart';
import '../domain/placed_order.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  if (FirebaseBootstrap.result.isReady) {
    return FirebaseOrderRepository();
  }
  return MockOrderRepository();
});

/// Recent orders for the signed-in customer (newest first).
final recentOrdersProvider =
    FutureProvider.autoDispose<List<PlacedOrder>>((ref) async {
  final result =
      await ref.watch(orderRepositoryProvider).fetchRecentOrders(limit: 50);
  return result.when(
    success: (orders) => orders,
    failure: (error, stackTrace) => throw error,
  );
});

void invalidateRecentOrders(WidgetRef ref) {
  ref.invalidate(recentOrdersProvider);
}

/// Live order for the track-order timeline (status updates from kitchen).
final watchedOrderProvider =
    StreamProvider.autoDispose.family<PlacedOrder, String>((ref, orderId) {
  return ref.watch(orderRepositoryProvider).watchOrder(orderId).map((result) {
    return result.when(
      success: (order) => order,
      failure: (error, stackTrace) => throw error,
    );
  });
});
