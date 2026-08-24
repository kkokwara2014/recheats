import '../../orders/domain/placed_order.dart';

/// Private feedback for Rechael after a completed order (not a public review).
class OrderFeedback {
  const OrderFeedback({
    required this.orderId,
    required this.displayCode,
    required this.rating,
    required this.createdAt,
    this.userId,
    this.comment = '',
  });

  final String orderId;
  final String displayCode;
  final String? userId;

  /// 1–5 stars.
  final int rating;
  final String comment;
  final DateTime createdAt;

  static bool isEligible(OrderStatus status) =>
      status == OrderStatus.completed || status == OrderStatus.delivered;

  Map<String, dynamic> toMap() => {
        'orderId': orderId,
        'displayCode': displayCode,
        if (userId != null) 'userId': userId,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
      };

  factory OrderFeedback.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return OrderFeedback(
      orderId: (map['orderId'] as String?)?.trim().isNotEmpty == true
          ? (map['orderId'] as String).trim()
          : id,
      displayCode: (map['displayCode'] as String?)?.trim() ?? '',
      userId: (map['userId'] as String?)?.trim(),
      rating: _readRating(map['rating']),
      comment: (map['comment'] as String?)?.trim() ?? '',
      createdAt: _readDate(map['createdAt']) ?? DateTime.now(),
    );
  }

  static int _readRating(Object? value) {
    if (value is int) return value.clamp(1, 5);
    if (value is num) return value.round().clamp(1, 5);
    return 5;
  }

  static DateTime? _readDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
