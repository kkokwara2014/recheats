import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/address_sign_in_prompt.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../application/profile_providers.dart';
import '../domain/address_label.dart';
import '../domain/saved_address.dart';

class SavedAddressesScreen extends ConsumerWidget {
  const SavedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(customerProfileProvider);
    final isSignedIn = profileAsync.asData?.value != null;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.savedAddresses)),
      floatingActionButton: isSignedIn
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.profileAddressEdit),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.addAddress),
            )
          : null,
      body: profileAsync.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppErrorView(
          error: error,
          onRetry: () => invalidateCustomerProfile(ref),
        ),
        data: (profile) {
          if (profile == null) {
            return const AddressSignInPrompt();
          }

          final addresses = profile.addresses;
          if (addresses.isEmpty) {
            return AppEmptyState(
              icon: Icons.location_off_outlined,
              title: AppStrings.savedAddressesEmptyTitle,
              message: AppStrings.savedAddressesEmptyBody,
              actionLabel: AppStrings.addAddress,
              onAction: () => context.push(AppRoutes.profileAddressEdit),
            );
          }

          return ResponsiveLayout(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                88,
              ),
              itemCount: addresses.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final address = addresses[index];
                return _AddressCard(
                  address: address,
                  onEdit: () => context.push(
                    AppRoutes.profileAddressEdit,
                    extra: address,
                  ),
                  onDelete: () => _confirmDelete(context, ref, address),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SavedAddress address,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteAddressTitle),
        content: Text(AppStrings.deleteAddressBody(address.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result =
        await ref.read(profileRepositoryProvider).deleteAddress(address.id);
    if (!context.mounted) return;

    result.when(
      success: (_) {
        invalidateCustomerProfile(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.addressDeleted)),
        );
      },
      failure: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.userMessage(error))),
        );
      },
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
  });

  final SavedAddress address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  IconData get _labelIcon => switch (address.addressLabel) {
        AddressLabel.home => Icons.home_outlined,
        AddressLabel.work => Icons.work_outline,
        AddressLabel.other => Icons.location_on_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notes = address.instructions?.trim();

    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _labelIcon,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            address.label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (address.isDefault)
                          Text(
                            AppStrings.defaultAddress,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      address.singleLine,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (notes != null && notes.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        notes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: AppStrings.delete,
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
