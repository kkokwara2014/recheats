import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/result.dart';
import '../../../services/firebase/firebase_bootstrap.dart';
import '../domain/place_order_request.dart';
import '../domain/placed_order.dart';

/// Persists customer orders with fulfillment details (no rider / GPS).
abstract class OrderRepository {
  Future<Result<PlacedOrder>> placeOrder(PlaceOrderRequest request);

  Future<Result<PlacedOrder>> fetchOrder(String orderId);

  /// Live status updates for the track-order timeline.
  Stream<Result<PlacedOrder>> watchOrder(String orderId);

  /// Kitchen / admin advances status (Firestore write is enough for MVP).
  Future<Result<PlacedOrder>> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  });

  Future<Result<List<PlacedOrder>>> fetchRecentOrders({int limit = 20});
}

String orderDisplayCodeFromSequence(int sequence) =>
    'RE${(1000 + sequence).toString().padLeft(4, '0')}';

String orderDisplayCodeFromId(String id) {
  final suffix = (id.hashCode.abs() % 9000) + 1000;
  return 'RE$suffix';
}

class MockOrderRepository implements OrderRepository {
  MockOrderRepository();

  final List<PlacedOrder> _orders = [];
  final Map<String, StreamController<PlacedOrder>> _controllers = {};
  int _nextId = 1;

  @override
  Future<Result<PlacedOrder>> placeOrder(PlaceOrderRequest request) async {
    if (request.lines.isEmpty) {
      return const Failure(ValidationException('Your cart is empty.'));
    }

    final sequence = _nextId++;
    final order = PlacedOrder(
      id: 'order-$sequence',
      displayCode: orderDisplayCodeFromSequence(sequence),
      userId: request.userId,
      lines: List.unmodifiable(request.lines),
      method: request.method,
      pickupLocation: request.pickupLocation,
      delivery: request.delivery,
      timing: request.timing,
      expectedPrepMinutes: request.expectedPrepMinutes,
      subtotal: request.subtotal,
      deliveryFee: request.deliveryFee,
      total: request.total,
      createdAt: DateTime.now(),
      status: OrderStatus.received,
      payment: request.payment,
    );
    _orders.insert(0, order);
    _emit(order);
    return Success(order);
  }

  @override
  Future<Result<PlacedOrder>> fetchOrder(String orderId) async {
    final order = _find(orderId);
    if (order == null) {
      return const Failure(NotFoundException('Order not found.'));
    }
    return Success(order);
  }

  @override
  Stream<Result<PlacedOrder>> watchOrder(String orderId) {
    final existing = _find(orderId);
    final controller = _controllers.putIfAbsent(
      orderId,
      () => StreamController<PlacedOrder>.broadcast(),
    );

    return Stream.multi((multi) {
      if (existing != null) {
        multi.add(Success(existing));
      } else {
        multi.add(const Failure(NotFoundException('Order not found.')));
      }
      final sub = controller.stream.listen(
        (order) => multi.add(Success(order)),
        onError: multi.addError,
      );
      multi.onCancel = () => sub.cancel();
    });
  }

  @override
  Future<Result<PlacedOrder>> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0) {
      return const Failure(NotFoundException('Order not found.'));
    }
    final updated = _orders[index].copyWith(status: status);
    _orders[index] = updated;
    _emit(updated);
    return Success(updated);
  }

  @override
  Future<Result<List<PlacedOrder>>> fetchRecentOrders({int limit = 20}) async {
    return Success(_orders.take(limit).toList(growable: false));
  }

  PlacedOrder? _find(String orderId) {
    for (final order in _orders) {
      if (order.id == orderId) return order;
    }
    return null;
  }

  void _emit(PlacedOrder order) {
    final controller = _controllers[order.id];
    if (controller != null && !controller.isClosed) {
      controller.add(order);
    }
  }
}

class FirebaseOrderRepository implements OrderRepository {
  FirebaseOrderRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  FirebaseAuth get _firebaseAuth => _auth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('orders');

  @override
  Future<Result<PlacedOrder>> placeOrder(PlaceOrderRequest request) async {
    if (!_ensureFirebase()) {
      return const Failure(
        UnknownAppException(
          'Orders are unavailable right now. Try again later.',
        ),
      );
    }
    if (request.lines.isEmpty) {
      return const Failure(ValidationException('Your cart is empty.'));
    }

    try {
      final userId = request.userId ?? _firebaseAuth.currentUser?.uid;
      final doc = _collection.doc();
      final order = PlacedOrder(
        id: doc.id,
        displayCode: orderDisplayCodeFromId(doc.id),
        userId: userId,
        lines: List.unmodifiable(request.lines),
        method: request.method,
        pickupLocation: request.pickupLocation,
        delivery: request.delivery,
        timing: request.timing,
        expectedPrepMinutes: request.expectedPrepMinutes,
        subtotal: request.subtotal,
        deliveryFee: request.deliveryFee,
        total: request.total,
        createdAt: DateTime.now(),
        status: OrderStatus.received,
        payment: request.payment,
      );

      await doc.set({
        ...order.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });
      return Success(order);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Place order failed: $error\n$stackTrace');
      }
      return Failure(
        UnknownAppException(
          'Could not record your order. Please try again.',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<Result<PlacedOrder>> fetchOrder(String orderId) async {
    if (!_ensureFirebase()) {
      return const Failure(
        UnknownAppException(
          'Orders are unavailable right now. Try again later.',
        ),
      );
    }
    try {
      final snapshot = await _collection.doc(orderId).get();
      if (!snapshot.exists || snapshot.data() == null) {
        return const Failure(NotFoundException('Order not found.'));
      }
      return Success(_fromDoc(snapshot));
    } catch (error, stackTrace) {
      if (error is AppException) {
        return Failure(error, stackTrace);
      }
      return Failure(
        UnknownAppException(
          'Could not load this order.',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  @override
  Stream<Result<PlacedOrder>> watchOrder(String orderId) {
    if (!_ensureFirebase()) {
      return Stream.value(
        const Failure(
          UnknownAppException(
            'Orders are unavailable right now. Try again later.',
          ),
        ),
      );
    }

    return _collection.doc(orderId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return const Failure(NotFoundException('Order not found.'));
      }
      try {
        return Success(_fromDoc(snapshot));
      } catch (error, stackTrace) {
        return Failure(
          UnknownAppException(
            'Could not load this order.',
            cause: error,
            stackTrace: stackTrace,
          ),
          stackTrace,
        );
      }
    });
  }

  @override
  Future<Result<PlacedOrder>> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    if (!_ensureFirebase()) {
      return const Failure(
        UnknownAppException(
          'Orders are unavailable right now. Try again later.',
        ),
      );
    }
    try {
      final doc = _collection.doc(orderId);
      await doc.update({
        'status': status.name,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });
      final snapshot = await doc.get();
      if (!snapshot.exists || snapshot.data() == null) {
        return const Failure(NotFoundException('Order not found.'));
      }
      return Success(_fromDoc(snapshot));
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Update order status failed: $error\n$stackTrace');
      }
      return Failure(
        UnknownAppException(
          'Could not update order status.',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<Result<List<PlacedOrder>>> fetchRecentOrders({int limit = 20}) async {
    if (!_ensureFirebase()) {
      return const Failure(
        UnknownAppException(
          'Orders are unavailable right now. Try again later.',
        ),
      );
    }
    try {
      final userId = _firebaseAuth.currentUser?.uid;
      if (userId == null) {
        return const Success([]);
      }
      final snapshot = await _collection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      final orders = snapshot.docs.map(_fromDoc).toList(growable: false);
      return Success(orders);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Fetch recent orders failed: $error\n$stackTrace');
      }
      return Failure(
        UnknownAppException(
          'Could not load your orders.',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  PlacedOrder _fromDoc(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    return PlacedOrder.fromMap(snapshot.data()!, id: snapshot.id);
  }

  bool _ensureFirebase() => FirebaseBootstrap.result.isReady;
}

class FakeOrderRepository implements OrderRepository {
  FakeOrderRepository();

  final List<PlacedOrder> orders = [];
  bool failNext = false;
  int _nextId = 1;
  final Map<String, StreamController<PlacedOrder>> _controllers = {};

  @override
  Future<Result<PlacedOrder>> placeOrder(PlaceOrderRequest request) async {
    if (_shouldFail()) {
      return const Failure(
        UnknownAppException('Could not record your order.'),
      );
    }
    if (request.lines.isEmpty) {
      return const Failure(ValidationException('Your cart is empty.'));
    }

    final sequence = _nextId++;
    final order = PlacedOrder(
      id: 'fake-order-$sequence',
      displayCode: orderDisplayCodeFromSequence(sequence),
      userId: request.userId,
      lines: List.unmodifiable(request.lines),
      method: request.method,
      pickupLocation: request.pickupLocation,
      delivery: request.delivery,
      timing: request.timing,
      expectedPrepMinutes: request.expectedPrepMinutes,
      subtotal: request.subtotal,
      deliveryFee: request.deliveryFee,
      total: request.total,
      createdAt: DateTime.now(),
      status: OrderStatus.received,
      payment: request.payment,
    );
    orders.insert(0, order);
    _emit(order);
    return Success(order);
  }

  @override
  Future<Result<PlacedOrder>> fetchOrder(String orderId) async {
    if (_shouldFail()) {
      return const Failure(UnknownAppException('Could not load order.'));
    }
    final order = _find(orderId);
    if (order == null) {
      return const Failure(NotFoundException('Order not found.'));
    }
    return Success(order);
  }

  @override
  Stream<Result<PlacedOrder>> watchOrder(String orderId) {
    final existing = _find(orderId);
    final controller = _controllers.putIfAbsent(
      orderId,
      () => StreamController<PlacedOrder>.broadcast(),
    );

    return Stream.multi((multi) {
      if (existing != null) {
        multi.add(Success(existing));
      } else {
        multi.add(const Failure(NotFoundException('Order not found.')));
      }
      final sub = controller.stream.listen(
        (order) => multi.add(Success(order)),
        onError: multi.addError,
      );
      multi.onCancel = () => sub.cancel();
    });
  }

  @override
  Future<Result<PlacedOrder>> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    if (_shouldFail()) {
      return const Failure(UnknownAppException('Could not update order.'));
    }
    final index = orders.indexWhere((order) => order.id == orderId);
    if (index < 0) {
      return const Failure(NotFoundException('Order not found.'));
    }
    final updated = orders[index].copyWith(status: status);
    orders[index] = updated;
    _emit(updated);
    return Success(updated);
  }

  @override
  Future<Result<List<PlacedOrder>>> fetchRecentOrders({int limit = 20}) async {
    if (_shouldFail()) {
      return const Failure(UnknownAppException('Could not load orders.'));
    }
    return Success(orders.take(limit).toList(growable: false));
  }

  PlacedOrder? _find(String orderId) {
    for (final order in orders) {
      if (order.id == orderId) return order;
    }
    return null;
  }

  void _emit(PlacedOrder order) {
    final controller = _controllers[order.id];
    if (controller != null && !controller.isClosed) {
      controller.add(order);
    }
  }

  bool _shouldFail() {
    if (!failNext) return false;
    failNext = false;
    return true;
  }
}
