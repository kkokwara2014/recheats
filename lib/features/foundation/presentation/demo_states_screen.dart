import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading.dart';

enum DemoStateKind { loading, empty, error }

/// Temporary previews for shared loading / empty / error widgets.
class DemoStatesScreen extends StatelessWidget {
  const DemoStatesScreen({
    super.key,
    required this.kind,
  });

  final DemoStateKind kind;

  @override
  Widget build(BuildContext context) {
    final title = switch (kind) {
      DemoStateKind.loading => 'Loading state',
      DemoStateKind.empty => 'Empty state',
      DemoStateKind.error => 'Error state',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.foundation),
        ),
      ),
      body: switch (kind) {
        DemoStateKind.loading => const AppLoading(
            message: 'Fetching the menu…',
          ),
        DemoStateKind.empty => AppEmptyState(
            title: 'Menu coming soon',
            message:
                'Rechael\'s Nigerian dishes will show up here once the menu module is ready.',
            icon: Icons.restaurant_menu_outlined,
            actionLabel: 'Back',
            onAction: () => context.go(AppRoutes.foundation),
          ),
        DemoStateKind.error => AppErrorView(
            title: AppStrings.somethingWentWrong,
            message: AppStrings.somethingWentWrongBody,
            onRetry: () => context.go(AppRoutes.foundation),
          ),
      },
    );
  }
}
