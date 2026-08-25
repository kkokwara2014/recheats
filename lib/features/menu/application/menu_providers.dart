import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/firebase/firebase_bootstrap.dart';
import '../data/menu_repository.dart';
import '../domain/food_item.dart';
import '../domain/menu_category.dart';

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  if (FirebaseBootstrap.result.isReady) {
    return FirebaseMenuRepository();
  }
  return MockMenuRepository();
});

/// Full catalog including unavailable items (kitchen manage screen).
final menuItemsProvider =
    FutureProvider.autoDispose<List<FoodItem>>((ref) async {
  final result = await ref.watch(menuRepositoryProvider).fetchMenu();
  return result.when(
    success: (items) => items,
    failure: (error, stackTrace) => throw error,
  );
});

/// Customer-facing catalog — sold-out dishes are omitted, not deleted.
final availableMenuItemsProvider =
    Provider.autoDispose<AsyncValue<List<FoodItem>>>((ref) {
  return ref.watch(menuItemsProvider).whenData(
        (items) => items.where((item) => item.isAvailable).toList(),
      );
});

final menuItemProvider =
    FutureProvider.autoDispose.family<FoodItem?, String>((ref, id) async {
  final result = await ref.watch(menuRepositoryProvider).fetchItem(id);
  return result.when(
    success: (item) => item,
    failure: (error, stackTrace) => throw error,
  );
});

/// Selected category chip on Home; null means show everything.
final selectedMenuCategoryProvider =
    NotifierProvider<SelectedMenuCategoryNotifier, MenuCategory?>(
  SelectedMenuCategoryNotifier.new,
);

class SelectedMenuCategoryNotifier extends Notifier<MenuCategory?> {
  @override
  MenuCategory? build() => null;

  void select(MenuCategory? category) => state = category;
}

void invalidateMenu(WidgetRef ref) {
  ref.invalidate(menuItemsProvider);
}

void invalidateMenuItem(WidgetRef ref, String id) {
  ref.invalidate(menuItemProvider(id));
  ref.invalidate(menuItemsProvider);
}
