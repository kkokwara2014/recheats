import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/firebase/firebase_bootstrap.dart';
import '../data/feedback_repository.dart';

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  if (FirebaseBootstrap.result.isReady) {
    return FirebaseFeedbackRepository();
  }
  return MockFeedbackRepository();
});

/// Whether this order already has feedback (local cache and/or Firestore).
final orderFeedbackSubmittedProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, orderId) async {
  return ref.watch(feedbackRepositoryProvider).hasSubmitted(orderId);
});

void invalidateOrderFeedback(WidgetRef ref, String orderId) {
  ref.invalidate(orderFeedbackSubmittedProvider(orderId));
}
