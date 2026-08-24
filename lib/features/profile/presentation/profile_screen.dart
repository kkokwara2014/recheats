import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../auth/application/auth_providers.dart';
import '../application/profile_providers.dart';
import 'widgets/profile_widgets.dart';

/// Customer hub for account details, history, and settings.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _loggingOut = false;

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);

    final result = await ref.read(authRepositoryProvider).logout();
    if (!mounted) return;

    result.when(
      success: (_) => context.go(AppRoutes.welcome),
      failure: (error, _) {
        setState(() => _loggingOut = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.userMessage(error))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(customerProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profileTitle)),
      body: profileAsync.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppErrorView(
          error: error,
          onRetry: () => invalidateCustomerProfile(ref),
        ),
        data: (profile) {
          if (profile == null) {
            return ResponsiveLayout(
              child: ProfileGuestCard(
                onSignIn: () => context.push(AppRoutes.login),
                onCreateAccount: () => context.push(AppRoutes.register),
              ),
            );
          }

          return ResponsiveLayout(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      ProfileAvatar(profile: profile, radius: 36),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              profile.email,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            if (profile.phone != null &&
                                profile.phone!.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                profile.phone!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: AppSpacing.lg),
                ProfileMenuTile(
                  icon: Icons.manage_accounts_outlined,
                  title: AppStrings.editProfile,
                  subtitle: AppStrings.editProfileSubtitle,
                  onTap: () => context.push(AppRoutes.profileEdit),
                ),
                ProfileMenuTile(
                  icon: Icons.location_on_outlined,
                  title: AppStrings.savedAddresses,
                  subtitle: profile.addresses.isEmpty
                      ? AppStrings.savedAddressesEmptyHint
                      : '${profile.addresses.length} saved',
                  onTap: () => context.push(AppRoutes.profileAddresses),
                ),
                ProfileMenuTile(
                  icon: Icons.restaurant_menu_outlined,
                  title: AppStrings.manageMenu,
                  subtitle: AppStrings.manageMenuSubtitle,
                  onTap: () => context.push(AppRoutes.menuManage),
                ),
                ProfileMenuTile(
                  icon: Icons.local_shipping_outlined,
                  title: AppStrings.fulfillmentSettings,
                  subtitle: AppStrings.fulfillmentSettingsMenuSubtitle,
                  onTap: () => context.push(AppRoutes.fulfillmentSettings),
                ),
                const Divider(height: AppSpacing.lg),
                ProfileMenuTile(
                  icon: Icons.receipt_long_outlined,
                  title: AppStrings.orderHistory,
                  onTap: () => context.push(AppRoutes.profileOrders),
                ),
                ProfileMenuTile(
                  icon: Icons.favorite_outline,
                  title: AppStrings.favorites,
                  onTap: () => context.push(AppRoutes.profileFavorites),
                ),
                ProfileMenuTile(
                  icon: Icons.notifications_outlined,
                  title: AppStrings.notifications,
                  onTap: () => context.push(AppRoutes.profileNotifications),
                ),
                ProfileMenuTile(
                  icon: Icons.help_outline,
                  title: AppStrings.help,
                  onTap: () => context.push(AppRoutes.profileHelp),
                ),
                const Divider(height: AppSpacing.lg),
                ProfileMenuTile(
                  icon: Icons.logout,
                  title: AppStrings.logout,
                  destructive: true,
                  onTap: _loggingOut ? null : _logout,
                ),
                if (_loggingOut)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: AppLoading(compact: true),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
