import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../cart/application/cart_providers.dart';
import '../../../profile/application/profile_providers.dart';

/// Personalized greeting + cart / profile shortcuts for the Home header.
class HomeGreetingHeader extends ConsumerWidget {
  const HomeGreetingHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(customerProfileProvider);
    final cartCount = ref.watch(cartProvider.select((c) => c.itemCount));

    final greeting = profileAsync.when(
      data: (profile) {
        final first = profile?.firstName.trim() ?? '';
        if (first.isEmpty) return AppStrings.homeGreetingGuest;
        return AppStrings.homeGreeting(first);
      },
      loading: () => AppStrings.homeGreetingGuest,
      error: (_, _) => AppStrings.homeGreetingGuest,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                AppStrings.homeTitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: AppStrings.openCart,
          onPressed: () => context.push(AppRoutes.cart),
          icon: Badge(
            isLabelVisible: cartCount > 0,
            label: Text('$cartCount'),
            child: const Icon(Icons.shopping_bag_outlined),
          ),
        ),
        IconButton(
          tooltip: AppStrings.openProfile,
          onPressed: () => context.push(AppRoutes.profile),
          icon: const Icon(Icons.person_outline),
        ),
      ],
    );
  }
}
