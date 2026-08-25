import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/result.dart';
import '../../../services/firebase/firebase_bootstrap.dart';
import '../domain/food_item.dart';
import '../domain/food_option.dart';
import '../domain/food_variation_group.dart';
import '../domain/menu_category.dart';

/// Reads and updates Rechael's digital restaurant menu.
abstract class MenuRepository {
  /// Full catalog including unavailable items (kitchen / manage views).
  Future<Result<List<FoodItem>>> fetchMenu();

  Future<Result<FoodItem?>> fetchItem(String id);

  /// Soft-hide without deleting — Rechael marks sold-out items unavailable.
  Future<Result<FoodItem>> setAvailability({
    required String id,
    required bool isAvailable,
  });

  /// Create or replace a catalog entry (kitchen tooling).
  Future<Result<FoodItem>> upsertItem(FoodItem item);
}

/// Local mutable catalog used until Firestore menu sync is seeded.
class MockMenuRepository implements MenuRepository {
  MockMenuRepository({List<FoodItem>? seed})
      : _items = List<FoodItem>.from(seed ?? defaultCatalog);

  final List<FoodItem> _items;

  static const List<FoodOption> _jollofProteins = [
    FoodOption(id: 'chicken', name: 'Chicken', priceDelta: 5),
    FoodOption(id: 'beef', name: 'Beef', priceDelta: 5),
    FoodOption(id: 'goat', name: 'Goat meat', priceDelta: 7),
    FoodOption(id: 'fish', name: 'Fish', priceDelta: 7),
  ];

  static const List<FoodItem> defaultCatalog = [
    FoodItem(
      id: 'jollof-rice',
      name: 'Jollof Rice',
      description: 'Served with fried plantain.',
      price: 15,
      category: MenuCategory.rice,
      preparationMinutes: 25,
      isSpecial: true,
      isPopular: true,
      portionSize: 'Regular plate · serves 1',
      ingredients: [
        'Long-grain rice',
        'Tomato stew base',
        'Peppers',
        'Onions',
        'Fried plantain',
      ],
      allergens: [],
      variationGroups: [
        FoodVariationGroup(
          id: 'protein',
          name: 'Protein options',
          options: _jollofProteins,
        ),
      ],
      addOns: [
        FoodOption(id: 'extra-plantain', name: 'Extra plantain', priceDelta: 3),
        FoodOption(id: 'colawi', name: 'Coleslaw', priceDelta: 2),
      ],
    ),
    FoodItem(
      id: 'fried-rice',
      name: 'Fried Rice',
      description: 'Savory Nigerian fried rice with mixed veggies.',
      price: 13.99,
      category: MenuCategory.rice,
      preparationMinutes: 25,
      isPopular: true,
      portionSize: 'Regular plate · serves 1',
      ingredients: [
        'Rice',
        'Mixed vegetables',
        'Curry seasoning',
        'Onions',
      ],
      variationGroups: [
        FoodVariationGroup(
          id: 'protein',
          name: 'Protein options',
          options: _jollofProteins,
        ),
      ],
    ),
    FoodItem(
      id: 'egusi-soup',
      name: 'Egusi Soup',
      description: 'Melon-seed soup with spinach and stockfish.',
      price: 16.50,
      category: MenuCategory.soups,
      preparationMinutes: 35,
      isSpecial: true,
      isPopular: true,
      portionSize: 'Bowl · serves 1–2',
      ingredients: [
        'Ground egusi (melon seeds)',
        'Spinach',
        'Palm oil',
        'Stockfish',
        'Assorted meats',
      ],
      allergens: ['Fish'],
      addOns: [
        FoodOption(id: 'extra-meat', name: 'Extra assorted meat', priceDelta: 6),
      ],
    ),
    FoodItem(
      id: 'ogbono-soup',
      name: 'Ogbono Soup',
      description: 'Draw soup with assorted meats, served hot.',
      price: 15.99,
      category: MenuCategory.soups,
      preparationMinutes: 35,
      isSpecial: true,
      portionSize: 'Bowl · serves 1–2',
      ingredients: [
        'Ground ogbono',
        'Palm oil',
        'Assorted meats',
        'Crayfish',
        'Peppers',
      ],
      allergens: ['Shellfish'],
    ),
    FoodItem(
      id: 'pounded-yam',
      name: 'Pounded Yam',
      description: 'Smooth swallow — perfect with any soup.',
      price: 6.99,
      category: MenuCategory.swallow,
      preparationMinutes: 15,
      isPopular: true,
      portionSize: 'Single wrap',
      ingredients: ['Yam flour'],
    ),
    FoodItem(
      id: 'eba',
      name: 'Eba',
      description: 'Garri swallow, freshly prepared to order.',
      price: 4.99,
      category: MenuCategory.swallow,
      preparationMinutes: 10,
      portionSize: 'Single wrap',
      ingredients: ['Garri (cassava)'],
    ),
    FoodItem(
      id: 'grilled-chicken',
      name: 'Grilled Chicken',
      description: 'Pepper-seasoned chicken, flame-grilled.',
      price: 12.99,
      category: MenuCategory.proteins,
      preparationMinutes: 30,
      isSpecial: true,
      isPopular: true,
      portionSize: 'Choose Regular or Large below',
      ingredients: [
        'Chicken',
        'Pepper seasoning',
        'Garlic',
        'Onions',
      ],
      variationGroups: [
        FoodVariationGroup(
          id: 'size',
          name: 'Portion',
          required: true,
          options: [
            FoodOption(id: 'regular', name: 'Regular', priceDelta: 0),
            FoodOption(id: 'large', name: 'Large', priceDelta: 4),
          ],
        ),
      ],
    ),
    FoodItem(
      id: 'beef-suya',
      name: 'Beef Suya',
      description: 'Spiced skewers with onion and tomato.',
      price: 11.50,
      category: MenuCategory.proteins,
      preparationMinutes: 20,
      isPopular: true,
      portionSize: '4 skewers',
      ingredients: [
        'Beef',
        'Yaji spice',
        'Onion',
        'Tomato',
      ],
      allergens: ['Peanuts'],
    ),
    FoodItem(
      id: 'puff-puff',
      name: 'Puff Puff',
      description: 'Golden fried dough bites, lightly sweet.',
      price: 5.99,
      category: MenuCategory.snacks,
      preparationMinutes: 15,
      isSpecial: true,
      portionSize: '6 pieces',
      ingredients: ['Flour', 'Yeast', 'Sugar', 'Nutmeg'],
      allergens: ['Gluten', 'Wheat'],
      addOns: [
        FoodOption(id: 'honey', name: 'Honey drizzle', priceDelta: 1),
      ],
    ),
    FoodItem(
      id: 'meat-pie',
      name: 'Meat Pie',
      description: 'Flaky pastry filled with seasoned mince.',
      price: 4.50,
      category: MenuCategory.snacks,
      preparationMinutes: 5,
      isPopular: true,
      portionSize: '1 pie',
      ingredients: [
        'Pastry dough',
        'Ground beef',
        'Potatoes',
        'Carrots',
      ],
      allergens: ['Gluten', 'Wheat', 'Dairy'],
    ),
    FoodItem(
      id: 'zobo',
      name: 'Zobo',
      description: 'Hibiscus drink with pineapple and ginger.',
      price: 3.99,
      category: MenuCategory.drinks,
      preparationMinutes: 5,
      isPopular: true,
      portionSize: '16 oz cup',
      ingredients: ['Hibiscus', 'Pineapple', 'Ginger', 'Cloves'],
    ),
    FoodItem(
      id: 'chapman',
      name: 'Chapman',
      description: 'Classic Nigerian mocktail, chilled.',
      price: 4.99,
      category: MenuCategory.drinks,
      preparationMinutes: 5,
      isSpecial: true,
      portionSize: '16 oz cup',
      ingredients: [
        'Fanta',
        'Sprite',
        'Grenadine',
        'Cucumber',
        'Angostura bitters',
      ],
    ),
  ];

  @override
  Future<Result<List<FoodItem>>> fetchMenu() async {
    return Success(List<FoodItem>.unmodifiable(_items));
  }

  @override
  Future<Result<FoodItem?>> fetchItem(String id) async {
    for (final item in _items) {
      if (item.id == id) return Success(item);
    }
    return const Success(null);
  }

  @override
  Future<Result<FoodItem>> setAvailability({
    required String id,
    required bool isAvailable,
  }) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) {
      return const Failure(NotFoundException('That menu item was not found.'));
    }
    final updated = _items[index].copyWith(isAvailable: isAvailable);
    _items[index] = updated;
    return Success(updated);
  }

  @override
  Future<Result<FoodItem>> upsertItem(FoodItem item) async {
    final index = _items.indexWhere((existing) => existing.id == item.id);
    if (index >= 0) {
      _items[index] = item;
    } else {
      _items.add(item);
    }
    return Success(item);
  }
}

/// Firestore-backed menu for production sync.
class FirebaseMenuRepository implements MenuRepository {
  FirebaseMenuRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('menuItems');

  @override
  Future<Result<List<FoodItem>>> fetchMenu() async {
    if (!_ensureFirebase()) {
      return const Failure(
        UnknownAppException('Menu is unavailable right now. Try again later.'),
      );
    }

    try {
      final snapshot = await _collection.orderBy('name').get();
      final items = snapshot.docs
          .map((doc) => FoodItem.fromMap(doc.data(), id: doc.id))
          .toList();
      if (items.isEmpty) {
        // First run after enabling Firebase — seed the local demo catalog
        // so Home / checkout keep working instead of showing an empty menu.
        await _seedDefaultCatalog();
        return Success(
          List<FoodItem>.unmodifiable(MockMenuRepository.defaultCatalog),
        );
      }
      return Success(items);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Fetch menu failed: $error\n$stackTrace');
      }
      return Failure(
        UnknownAppException(
          'Could not load the menu. Please try again.',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  Future<void> _seedDefaultCatalog() async {
    final batch = _db.batch();
    for (final item in MockMenuRepository.defaultCatalog) {
      batch.set(_collection.doc(item.id), item.toMap());
    }
    await batch.commit();
  }

  @override
  Future<Result<FoodItem?>> fetchItem(String id) async {
    if (!_ensureFirebase()) {
      return const Failure(
        UnknownAppException('Menu is unavailable right now. Try again later.'),
      );
    }

    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists || doc.data() == null) return const Success(null);
      return Success(FoodItem.fromMap(doc.data()!, id: doc.id));
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Fetch menu item failed: $error\n$stackTrace');
      }
      return Failure(
        UnknownAppException(
          'Could not load that dish. Please try again.',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<Result<FoodItem>> setAvailability({
    required String id,
    required bool isAvailable,
  }) async {
    if (!_ensureFirebase()) {
      return const Failure(
        UnknownAppException('Menu is unavailable right now. Try again later.'),
      );
    }

    try {
      final ref = _collection.doc(id);
      final doc = await ref.get();
      if (!doc.exists || doc.data() == null) {
        return const Failure(NotFoundException('That menu item was not found.'));
      }

      await ref.set({
        'isAvailable': isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final refreshed = await ref.get();
      return Success(FoodItem.fromMap(refreshed.data()!, id: refreshed.id));
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Set availability failed: $error\n$stackTrace');
      }
      return Failure(
        UnknownAppException(
          'Could not update availability. Please try again.',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<Result<FoodItem>> upsertItem(FoodItem item) async {
    if (!_ensureFirebase()) {
      return const Failure(
        UnknownAppException('Menu is unavailable right now. Try again later.'),
      );
    }

    try {
      final data = {
        ...item.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _collection.doc(item.id).set(data, SetOptions(merge: true));
      return Success(item);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Upsert menu item failed: $error\n$stackTrace');
      }
      return Failure(
        UnknownAppException(
          'Could not save that menu item. Please try again.',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  bool _ensureFirebase() => FirebaseBootstrap.result.isReady;
}

/// In-memory menu for widget tests.
class FakeMenuRepository implements MenuRepository {
  FakeMenuRepository({List<FoodItem>? seed})
      : _items = List<FoodItem>.from(seed ?? MockMenuRepository.defaultCatalog);

  final List<FoodItem> _items;
  bool failNext = false;

  @override
  Future<Result<List<FoodItem>>> fetchMenu() async {
    if (_shouldFail()) {
      return const Failure(UnknownAppException('Could not load the menu.'));
    }
    return Success(List<FoodItem>.unmodifiable(_items));
  }

  @override
  Future<Result<FoodItem?>> fetchItem(String id) async {
    if (_shouldFail()) {
      return const Failure(UnknownAppException('Could not load that dish.'));
    }
    for (final item in _items) {
      if (item.id == id) return Success(item);
    }
    return const Success(null);
  }

  @override
  Future<Result<FoodItem>> setAvailability({
    required String id,
    required bool isAvailable,
  }) async {
    if (_shouldFail()) {
      return const Failure(
        UnknownAppException('Could not update availability.'),
      );
    }
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) {
      return const Failure(NotFoundException('That menu item was not found.'));
    }
    final updated = _items[index].copyWith(isAvailable: isAvailable);
    _items[index] = updated;
    return Success(updated);
  }

  @override
  Future<Result<FoodItem>> upsertItem(FoodItem item) async {
    if (_shouldFail()) {
      return const Failure(
        UnknownAppException('Could not save that menu item.'),
      );
    }
    final index = _items.indexWhere((existing) => existing.id == item.id);
    if (index >= 0) {
      _items[index] = item;
    } else {
      _items.add(item);
    }
    return Success(item);
  }

  bool _shouldFail() {
    if (!failNext) return false;
    failNext = false;
    return true;
  }
}
