import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../cart/application/cart_providers.dart';
import '../../menu/application/menu_providers.dart';
import '../../menu/domain/food_item.dart';
import 'widgets/home_category_chips.dart';
import 'widgets/home_food_carousel.dart';
import 'widgets/home_greeting_header.dart';
import 'widgets/home_hero_banner.dart';
import 'widgets/home_section_header.dart';

/// Primary customer discovery screen — food is visible without multi-step nav.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();
  final _categoriesKey = GlobalKey();
  final _specialsKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  void _openItem(FoodItem item) {
    context.push(AppRoutes.menuItemPath(item.id));
  }

  void _onAdd(FoodItem item) {
    if (item.hasCustomizations) {
      _openItem(item);
      return;
    }

    ref.read(cartProvider.notifier).addItem(
          foodItemId: item.id,
          name: item.name,
          unitPrice: item.price,
          quantity: 1,
          imageAsset: item.imageAsset,
          imageUrl: item.imageUrl,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.addedToCartNamed(item.name)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onOrderNow() {
    _scrollTo(_specialsKey);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.orderNowHint),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(availableMenuItemsProvider);
    final selectedCategory = ref.watch(selectedMenuCategoryProvider);

    return Scaffold(
      body: SafeArea(
        child: menuAsync.when(
          loading: () => const AppLoading(),
          error: (error, _) => AppErrorView(
            message: error.toString(),
            onRetry: () => invalidateMenu(ref),
          ),
          data: (items) {
            final filtered = selectedCategory == null
                ? items
                : items
                    .where((item) => item.category == selectedCategory)
                    .toList();
            final specials =
                filtered.where((item) => item.isSpecial).toList();
            final popular =
                filtered.where((item) => item.isPopular).toList();

            return ResponsiveLayout(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.md,
                      bottom: AppSpacing.lg,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const HomeGreetingHeader(),
                        const SizedBox(height: AppSpacing.lg),
                        HomeHeroBanner(
                          onBrowseMenu: () => _scrollTo(_categoriesKey),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        KeyedSubtree(
                          key: _categoriesKey,
                          child: const HomeCategoryChips(),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        KeyedSubtree(
                          key: _specialsKey,
                          child: const HomeSectionHeader(
                            title: AppStrings.todaysSpecials,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        HomeFoodCarousel(
                          items: specials,
                          onAdd: _onAdd,
                          onItemTap: _openItem,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const HomeSectionHeader(
                          title: AppStrings.popularMeals,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        HomeFoodCarousel(
                          items: popular,
                          onAdd: _onAdd,
                          onItemTap: _openItem,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _onOrderNow,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.textOnAccent,
                            ),
                            child: const Text(AppStrings.orderNow),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
