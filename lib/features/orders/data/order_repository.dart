import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/result.dart';
import '../../../services/firebase/firebase_bootstrap.dart';
import '../domain/place_order_request.dart';
import '../domain/placed_order.dart';

/// Persists customer orders with fulfillment details (no rider dispatch).
abstract class OrderRepository {
  Future<Result<PlacedOrder>> placeOrder(PlaceOrderRequest request);

  Future<Result<List<PlacedOrder>>> fetchRecentOrders({int limit = 20});
}

class MockOrderRepository implements OrderRepository {
  MockOrderRepository();

  final List<PlacedOrder> _orders = [];
  int _nextId = 1;

  @override
  Future<Result<PlacedOrder>> placeOrder(PlaceOrderRequest request) async {
    if (request.lines.isEmpty) {
      return const Failure(ValidationException('Your cart is empty.'));
    }

    final order = PlacedOrder(
      id: 'order-${_nextId++}',
      userId: request.userId,
      lines: List.unmodifiable(request.lines),
      method: request.method,
      pickupLocation: request.pickupLocation,
      delivery: request.delivery,
      timing: request.timing,
      subtotal: request.subtotal,
      deliveryFee: request.deliveryFee,
      total: request.total,
      createdAt: DateTime.now(),
    );
    _orders.insert(0, order);
    return Success(order);
  }

  @override
  Future<Result<List<PlacedOrder>>> fetchRecentOrders({int limit = 20}) async {
    return Success(_orders.take(limit).toList(growable: false));
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
        userId: userId,
        lines: List.unmodifiable(request.lines),
        method: request.method,
        pickupLocation: request.pickupLocation,
        delivery: request.delivery,
        timing: request.timing,
        subtotal: request.subtotal,
        deliveryFee: request.deliveryFee,
        total: request.total,
        createdAt: DateTime.now(),
      );

      await doc.set({
        ...order.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
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
  Future<Result<List<PlacedOrder>>> fetchRecentOrders({int limit = 20}) async {
    // Order history UI remains a placeholder; listing comes in a later module.
    return const Success([]);
  }

  bool _ensureFirebase() => FirebaseBootstrap.result.isReady;
}

class FakeOrderRepository implements OrderRepository {
  FakeOrderRepository();

  final List<PlacedOrder> orders = [];
  bool failNext = false;
  int _nextId = 1;

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

    final order = PlacedOrder(
      id: 'fake-order-${_nextId++}',
      userId: request.userId,
      lines: List.unmodifiable(request.lines),
      method: request.method,
      pickupLocation: request.pickupLocation,
      delivery: request.delivery,
      timing: request.timing,
      subtotal: request.subtotal,
      deliveryFee: request.deliveryFee,
      total: request.total,
      createdAt: DateTime.now(),
    );
    orders.insert(0, order);
    return Success(order);
  }

  @override
  Future<Result<List<PlacedOrder>>> fetchRecentOrders({int limit = 20}) async {
    if (_shouldFail()) {
      return const Failure(UnknownAppException('Could not load orders.'));
    }
    return Success(orders.take(limit).toList(growable: false));
  }

  bool _shouldFail() {
    if (!failNext) return false;
    failNext = false;
    return true;
  }
}
