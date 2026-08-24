import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return MockOrderRepository();
});
