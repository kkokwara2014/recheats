/// When the customer wants the order ready — ASAP or a scheduled slot.
enum OrderTimingMode {
  asap,
  scheduled,
}

/// Checkout order timing choice for batch-friendly kitchen planning.
class OrderTiming {
  const OrderTiming({
    this.mode = OrderTimingMode.asap,
    this.scheduledAt,
  });

  final OrderTimingMode mode;
  final DateTime? scheduledAt;

  bool get isAsap => mode == OrderTimingMode.asap;

  bool get isScheduled => mode == OrderTimingMode.scheduled;

  bool get isComplete {
    if (isAsap) return true;
    final at = scheduledAt;
    if (at == null) return false;
    return !at.isBefore(DateTime.now());
  }

  /// e.g. "ASAP" or "Friday, 6:30 PM"
  String get displayLabel {
    if (isAsap) return 'ASAP';
    final at = scheduledAt;
    if (at == null) return 'Schedule order';
    return formatScheduledAt(at);
  }

  OrderTiming copyWith({
    OrderTimingMode? mode,
    DateTime? scheduledAt,
    bool clearScheduledAt = false,
  }) {
    return OrderTiming(
      mode: mode ?? this.mode,
      scheduledAt: clearScheduledAt ? null : (scheduledAt ?? this.scheduledAt),
    );
  }

  Map<String, dynamic> toMap() => {
        'mode': mode.name,
        if (scheduledAt != null) 'scheduledAt': scheduledAt!.toIso8601String(),
      };

  factory OrderTiming.fromMap(Map<String, dynamic> map) {
    final modeName = map['mode'] as String? ?? OrderTimingMode.asap.name;
    final mode = OrderTimingMode.values.firstWhere(
      (value) => value.name == modeName,
      orElse: () => OrderTimingMode.asap,
    );
    final scheduledRaw = map['scheduledAt'];
    DateTime? scheduledAt;
    if (scheduledRaw is String) {
      scheduledAt = DateTime.tryParse(scheduledRaw);
    } else if (scheduledRaw is DateTime) {
      scheduledAt = scheduledRaw;
    }
    return OrderTiming(mode: mode, scheduledAt: scheduledAt);
  }

  /// Formats like "Friday, 6:30 PM" without needing the intl package.
  static String formatScheduledAt(DateTime at) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final weekday = weekdays[at.weekday - 1];
    final hour24 = at.hour;
    final minute = at.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$weekday, $hour12:$minute $period';
  }
}
