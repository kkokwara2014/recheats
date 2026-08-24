import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../application/profile_providers.dart';
import '../domain/notification_prefs.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.orderHistory)),
      body: const AppEmptyState(
        icon: Icons.receipt_long_outlined,
        title: AppStrings.orderHistoryEmptyTitle,
        message: AppStrings.orderHistoryEmptyBody,
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.favorites)),
      body: const AppEmptyState(
        icon: Icons.favorite_outline,
        title: AppStrings.favoritesEmptyTitle,
        message: AppStrings.favoritesEmptyBody,
      ),
    );
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(customerProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.notifications)),
      body: profileAsync.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppErrorView(
          error: error,
          onRetry: () => invalidateCustomerProfile(ref),
        ),
        data: (profile) {
          if (profile == null) {
            return const AppErrorView(
              title: AppStrings.profileGuestTitle,
              message: AppStrings.profileGuestBody,
            );
          }

          final prefs = profile.notifications;

          Future<void> update(NotificationPrefs next) async {
            final result = await ref
                .read(profileRepositoryProvider)
                .updateNotifications(next);
            if (!context.mounted) return;
            result.when(
              success: (_) => invalidateCustomerProfile(ref),
              failure: (error, _) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ErrorHandler.userMessage(error))),
                );
              },
            );
          }

          return ResponsiveLayout(
            child: ListView(
              children: [
                SwitchListTile(
                  title: const Text(AppStrings.notifOrderUpdates),
                  subtitle: const Text(AppStrings.notifOrderUpdatesBody),
                  value: prefs.orderUpdates,
                  onChanged: (value) => update(
                    prefs.copyWith(orderUpdates: value),
                  ),
                ),
                SwitchListTile(
                  title: const Text(AppStrings.notifPromotions),
                  subtitle: const Text(AppStrings.notifPromotionsBody),
                  value: prefs.promotions,
                  onChanged: (value) => update(
                    prefs.copyWith(promotions: value),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.help)),
      body: ResponsiveLayout(
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text(AppStrings.helpKitchen),
              subtitle: const Text(AppStrings.locationHint),
            ),
            ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: const Text(AppStrings.helpHoursTitle),
              subtitle: const Text(AppStrings.helpHoursBody),
            ),
            ListTile(
              leading: const Icon(Icons.support_agent_outlined),
              title: const Text(AppStrings.helpContactTitle),
              subtitle: const Text(AppStrings.helpContactBody),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppStrings.helpFaqTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const ExpansionTile(
              title: Text(AppStrings.helpFaq1Q),
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(AppStrings.helpFaq1A),
                ),
              ],
            ),
            const ExpansionTile(
              title: Text(AppStrings.helpFaq2Q),
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(AppStrings.helpFaq2A),
                ),
              ],
            ),
            const ExpansionTile(
              title: Text(AppStrings.helpFaq3Q),
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(AppStrings.helpFaq3A),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
