import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_repository.dart';
import '../domain/customer_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return FirebaseProfileRepository();
});

final customerProfileProvider =
    FutureProvider.autoDispose<CustomerProfile?>((ref) async {
  final result = await ref.watch(profileRepositoryProvider).fetchProfile();
  return result.when(
    success: (profile) => profile,
    failure: (error, stackTrace) => throw error,
  );
});

void invalidateCustomerProfile(WidgetRef ref) {
  ref.invalidate(customerProfileProvider);
}
