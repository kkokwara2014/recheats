import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_strings.dart';
import '../routing/app_routes.dart';
import '../../features/profile/application/profile_providers.dart';
import 'app_empty_state.dart';
import 'app_error_view.dart';
import 'app_loading.dart';

/// Shows [child] only when the signed-in user has `isAdmin == true`.
class AdminGate extends ConsumerWidget {
  const AdminGate({
    super.key,
    required this.child,
    this.title = AppStrings.adminAccessDeniedTitle,
  });

  final Widget child;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(customerProfileProvider);

    return profileAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const AppLoading(),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: AppErrorView(
          error: error,
          onRetry: () => invalidateCustomerProfile(ref),
        ),
      ),
      data: (profile) {
        if (profile == null || !profile.isAdmin) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: AppEmptyState(
              icon: Icons.lock_outline,
              title: AppStrings.adminAccessDeniedTitle,
              message: AppStrings.adminAccessDeniedBody,
              actionLabel: AppStrings.navHome,
              onAction: () => context.go(AppRoutes.home),
            ),
          );
        }
        return child;
      },
    );
  }
}
