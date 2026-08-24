import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../application/profile_providers.dart';
import '../domain/notification_prefs.dart';

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
