/// Stripe / order payment lifecycle. Stored on the order — not PAN data.
enum PaymentStatus {
  /// Intent created; customer has not completed PaymentSheet yet.
  requiresAction,

  /// Charge succeeded (or mock local success).
  succeeded,

  /// Customer dismissed PaymentSheet without paying.
  canceled,

  /// Stripe or backend reported a failure.
  failed,
}
