import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/order_timing.dart';

/// ASAP vs schedule — supports batch meal prep for a home kitchen.
class OrderTimingSelector extends StatelessWidget {
  const OrderTimingSelector({
    super.key,
    required this.timing,
    required this.onSelectAsap,
    required this.onSelectScheduled,
    required this.onPickSlot,
  });

  final OrderTiming timing;
  final VoidCallback onSelectAsap;
  final VoidCallback onSelectScheduled;
  final VoidCallback onPickSlot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.orderTimingTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _TimingTile(
          title: AppStrings.orderTimingAsap,
          subtitle: AppStrings.orderTimingAsapBody,
          icon: Icons.bolt_outlined,
          selected: timing.isAsap,
          onTap: onSelectAsap,
        ),
        const SizedBox(height: AppSpacing.xs),
        _TimingTile(
          title: AppStrings.orderTimingSchedule,
          subtitle: timing.isScheduled && timing.scheduledAt != null
              ? OrderTiming.formatScheduledAt(timing.scheduledAt!)
              : AppStrings.orderTimingScheduleBody,
          icon: Icons.schedule_outlined,
          selected: timing.isScheduled,
          onTap: onSelectScheduled,
          trailing: timing.isScheduled
              ? TextButton(
                  onPressed: onPickSlot,
                  child: Text(
                    timing.scheduledAt == null
                        ? AppStrings.orderTimingPickSlot
                        : AppStrings.orderTimingChangeSlot,
                  ),
                )
              : null,
        ),
      ],
    );
  }
}

class _TimingTile extends StatelessWidget {
  const _TimingTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? AppColors.surfaceMuted : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color:
                            selected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: trailing,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
