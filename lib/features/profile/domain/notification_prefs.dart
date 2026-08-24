/// Push / in-app notification preferences for the customer.
class NotificationPrefs {
  const NotificationPrefs({
    this.orderUpdates = true,
    this.promotions = false,
  });

  final bool orderUpdates;
  final bool promotions;

  NotificationPrefs copyWith({
    bool? orderUpdates,
    bool? promotions,
  }) {
    return NotificationPrefs(
      orderUpdates: orderUpdates ?? this.orderUpdates,
      promotions: promotions ?? this.promotions,
    );
  }

  Map<String, dynamic> toMap() => {
        'orderUpdates': orderUpdates,
        'promotions': promotions,
      };

  factory NotificationPrefs.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const NotificationPrefs();
    return NotificationPrefs(
      orderUpdates: map['orderUpdates'] as bool? ?? true,
      promotions: map['promotions'] as bool? ?? false,
    );
  }
}
