import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/utils/result.dart';
import '../../menu/application/menu_providers.dart';
import '../../menu/domain/food_item.dart';
import '../../profile/application/profile_providers.dart';
import '../data/favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FirebaseFavoritesRepository();
});

final favoriteIdsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final result = await ref.watch(favoritesRepositoryProvider).fetchFavoriteIds();
  return result.when(
    success: (ids) => ids,
    failure: (error, stackTrace) => throw error,
  );
});

/// Menu items in favorite order (most recently saved first).
final favoriteFoodItemsProvider =
    Provider.autoDispose<AsyncValue<List<FoodItem>>>((ref) {
  final idsAsync = ref.watch(favoriteIdsProvider);
  final menuAsync = ref.watch(menuItemsProvider);

  return idsAsync.when(
    loading: () => const AsyncLoading(),
    error: (error, stackTrace) => AsyncError(error, stackTrace),
    data: (ids) {
      return menuAsync.when(
        loading: () => const AsyncLoading(),
        error: (error, stackTrace) => AsyncError(error, stackTrace),
        data: (items) {
          final byId = {for (final item in items) item.id: item};
          return AsyncData([
            for (final id in ids)
              if (byId.containsKey(id)) byId[id]!,
          ]);
        },
      );
    },
  );
});

void invalidateFavorites(WidgetRef ref) {
  ref.invalidate(favoriteIdsProvider);
}

/// Adds or removes a favorite. Prompts guests to sign in.
Future<void> toggleFavorite({
  required BuildContext context,
  required WidgetRef ref,
  required String foodItemId,
  String? foodItemName,
}) async {
  final messenger = ScaffoldMessenger.of(context);

  CustomerGateResult gate;
  try {
    final profile = await ref.read(customerProfileProvider.future);
    gate = profile == null
        ? CustomerGateResult.needsSignIn
        : CustomerGateResult.signedIn;
  } catch (_) {
    gate = CustomerGateResult.needsSignIn;
  }

  if (!context.mounted) return;

  if (gate == CustomerGateResult.needsSignIn) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text(AppStrings.favoritesSignInRequired),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.push(AppRoutes.login);
    return;
  }

  final ids = await ref.read(favoriteIdsProvider.future);
  if (!context.mounted) return;

  final repo = ref.read(favoritesRepositoryProvider);
  final wasFavorite = ids.contains(foodItemId);
  final Result<List<String>> result = wasFavorite
      ? await repo.removeFavorite(foodItemId)
      : await repo.addFavorite(foodItemId);

  if (!context.mounted) return;

  result.when(
    success: (_) {
      invalidateFavorites(ref);
      final name = (foodItemName ?? '').trim();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            wasFavorite
                ? (name.isEmpty
                    ? AppStrings.favoriteRemoved
                    : AppStrings.favoriteRemovedNamed(name))
                : (name.isEmpty
                    ? AppStrings.favoriteAdded
                    : AppStrings.favoriteAddedNamed(name)),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    },
    failure: (error, _) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.userMessage(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    },
  );
}

enum CustomerGateResult { signedIn, needsSignIn }
