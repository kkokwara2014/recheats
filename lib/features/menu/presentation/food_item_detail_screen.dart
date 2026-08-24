import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../cart/application/cart_providers.dart';
import '../../cart/domain/cart_line_item.dart';
import '../application/menu_providers.dart';
import '../domain/food_item.dart';
import '../domain/food_option.dart';
import '../domain/food_variation_group.dart';
import 'widgets/food_image.dart';

/// Customer detail: image, info, customizations, quantity, notes, add to cart.
class FoodItemDetailScreen extends ConsumerStatefulWidget {
  const FoodItemDetailScreen({
    super.key,
    required this.itemId,
    this.editingLine,
  });

  final String itemId;

  /// When set, saving updates this cart line instead of adding a new one.
  final CartLineItem? editingLine;

  @override
  ConsumerState<FoodItemDetailScreen> createState() =>
      _FoodItemDetailScreenState();
}

class _FoodItemDetailScreenState extends ConsumerState<FoodItemDetailScreen> {
  /// groupId → selected option id
  final Map<String, String> _variationSelections = {};
  final Set<String> _selectedAddOnIds = {};
  final _instructionsController = TextEditingController();

  int _quantity = 1;

  bool get _isEditing => widget.editingLine != null;

  @override
  void initState() {
    super.initState();
    final line = widget.editingLine;
    if (line == null) return;

    _quantity = line.quantity.clamp(1, 99);
    _instructionsController.text = line.specialInstructions;
    _variationSelections.addAll(line.variationSelections);
    _selectedAddOnIds.addAll(line.addOns.map((a) => a.id));
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  String? _selectedVariationId(FoodVariationGroup group) {
    final selected = _variationSelections[group.id];
    if (selected != null) return selected;
    if (group.required && group.options.isNotEmpty) {
      return group.options.first.id;
    }
    return null;
  }

  FoodOption? _selectedOption(FoodVariationGroup group) {
    final selectedId = _selectedVariationId(group);
    if (selectedId == null) return null;
    for (final option in group.options) {
      if (option.id == selectedId) return option;
    }
    return null;
  }

  double _unitPrice(FoodItem item) {
    var total = item.price;

    for (final group in item.variationGroups) {
      final option = _selectedOption(group);
      if (option != null) total += option.priceDelta;
    }

    for (final addOn in item.addOns) {
      if (_selectedAddOnIds.contains(addOn.id)) {
        total += addOn.priceDelta;
      }
    }

    return total;
  }

  double _lineTotal(FoodItem item) => _unitPrice(item) * _quantity;

  bool _canAdd(FoodItem item) {
    if (!item.isAvailable) return false;
    for (final group in item.variationGroups) {
      if (group.required && _selectedVariationId(group) == null) {
        return false;
      }
    }
    return true;
  }

  List<String> _variationLabels(FoodItem item) {
    final labels = <String>[];
    for (final group in item.variationGroups) {
      final option = _selectedOption(group);
      if (option == null) continue;
      labels.add('${group.name}: ${option.name}');
    }
    return labels;
  }

  Map<String, String> _currentVariationSelections(FoodItem item) {
    final selections = <String, String>{};
    for (final group in item.variationGroups) {
      final id = _selectedVariationId(group);
      if (id != null) selections[group.id] = id;
    }
    return selections;
  }

  List<FoodOption> _selectedAddOns(FoodItem item) {
    return item.addOns
        .where((addOn) => _selectedAddOnIds.contains(addOn.id))
        .toList();
  }

  void _onAddToCart(FoodItem item) {
    final notifier = ref.read(cartProvider.notifier);
    final editingLine = widget.editingLine;

    if (editingLine != null) {
      notifier.replaceLine(
        lineId: editingLine.id,
        foodItemId: item.id,
        name: item.name,
        unitPrice: _unitPrice(item),
        quantity: _quantity,
        imageAsset: item.imageAsset,
        imageUrl: item.imageUrl,
        variationLabels: _variationLabels(item),
        variationSelections: _currentVariationSelections(item),
        addOns: _selectedAddOns(item),
        specialInstructions: _instructionsController.text,
      );
    } else {
      notifier.addItem(
        foodItemId: item.id,
        name: item.name,
        unitPrice: _unitPrice(item),
        quantity: _quantity,
        imageAsset: item.imageAsset,
        imageUrl: item.imageUrl,
        variationLabels: _variationLabels(item),
        variationSelections: _currentVariationSelections(item),
        addOns: _selectedAddOns(item),
        specialInstructions: _instructionsController.text,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing
              ? AppStrings.cartUpdatedNamed(item.name)
              : AppStrings.addedToCartNamed(item.name),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (_isEditing && context.canPop()) {
      context.pop();
    }
  }

  void _setQuantity(int value) {
    setState(() => _quantity = value.clamp(1, 99));
  }

  @override
  Widget build(BuildContext context) {
    final asyncItem = ref.watch(menuItemProvider(widget.itemId));

    return Scaffold(
      body: asyncItem.when(
        loading: () => const AppLoading(),
        error: (error, _) => Scaffold(
          appBar: AppBar(),
          body: AppErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(menuItemProvider(widget.itemId)),
          ),
        ),
        data: (item) {
          if (item == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const AppErrorView(
                message: 'That dish is no longer on the menu.',
              ),
            );
          }

          final theme = Theme.of(context);
          final total = _lineTotal(item);
          final canAdd = _canAdd(item);

          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      expandedHeight: 300,
                      title: Text(item.name),
                      flexibleSpace: FlexibleSpaceBar(
                        background: FoodImage(item: item),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: ResponsiveLayout(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!item.isAvailable) ...[
                                const _UnavailableBanner(),
                                const SizedBox(height: AppSpacing.md),
                              ],
                              Text(
                                item.name,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                item.formattedPrice,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  if (item.preparationLabel.isNotEmpty)
                                    _MetaChip(
                                      icon: Icons.schedule_rounded,
                                      label: AppStrings.prepMinutes(
                                        item.preparationMinutes,
                                      ),
                                    ),
                                  _MetaChip(
                                    icon: Icons.restaurant_rounded,
                                    label: item.category.label,
                                  ),
                                  if (item.portionSize != null &&
                                      item.portionSize!.isNotEmpty)
                                    _MetaChip(
                                      icon: Icons.ramen_dining_rounded,
                                      label: item.portionSize!,
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                item.description,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              if (item.portionSize != null &&
                                  item.portionSize!.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.lg),
                                _SectionTitle(
                                  title: AppStrings.portionSizeTitle,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  item.portionSize!,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                              if (item.ingredients.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.lg),
                                _SectionTitle(
                                  title: AppStrings.ingredientsTitle,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Wrap(
                                  spacing: AppSpacing.xs,
                                  runSpacing: AppSpacing.xs,
                                  children: [
                                    for (final ingredient in item.ingredients)
                                      Chip(
                                        label: Text(ingredient),
                                        visualDensity: VisualDensity.compact,
                                        backgroundColor: AppColors.surfaceMuted,
                                        side: BorderSide.none,
                                      ),
                                  ],
                                ),
                              ],
                              if (item.allergens.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.lg),
                                _SectionTitle(
                                  title: AppStrings.allergensTitle,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                _AllergenBanner(allergens: item.allergens),
                              ],
                              if (item.hasCustomizations) ...[
                                const SizedBox(height: AppSpacing.xl),
                                _SectionTitle(
                                  title: AppStrings.customizeYourMeal,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                for (final group in item.variationGroups) ...[
                                  _VariationGroupSection(
                                    group: group,
                                    selectedId: _selectedVariationId(group),
                                    enabled: item.isAvailable,
                                    onSelected: (optionId) {
                                      setState(() {
                                        _variationSelections[group.id] =
                                            optionId;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                ],
                                if (item.addOns.isNotEmpty)
                                  _AddOnsSection(
                                    addOns: item.addOns,
                                    selectedIds: _selectedAddOnIds,
                                    enabled: item.isAvailable,
                                    onToggle: (id) {
                                      setState(() {
                                        if (_selectedAddOnIds.contains(id)) {
                                          _selectedAddOnIds.remove(id);
                                        } else {
                                          _selectedAddOnIds.add(id);
                                        }
                                      });
                                    },
                                  ),
                              ],
                              const SizedBox(height: AppSpacing.xl),
                              _SectionTitle(title: AppStrings.quantityTitle),
                              const SizedBox(height: AppSpacing.sm),
                              _QuantityStepper(
                                quantity: _quantity,
                                enabled: item.isAvailable,
                                onChanged: _setQuantity,
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              _SectionTitle(
                                title: AppStrings.specialInstructionsTitle,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              TextField(
                                controller: _instructionsController,
                                enabled: item.isAvailable,
                                maxLines: 3,
                                maxLength: 200,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: const InputDecoration(
                                  hintText: AppStrings.specialInstructionsHint,
                                  alignLabelWithHint: true,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxl),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Material(
                  elevation: 8,
                  color: AppColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppStrings.itemTotal,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '\$${total.toStringAsFixed(2)}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: canAdd ? () => _onAddToCart(item) : null,
                          child: Text(
                            !item.isAvailable
                                ? AppStrings.unavailableLabel
                                : _isEditing
                                    ? AppStrings.updateCartItem
                                    : AppStrings.addToCart,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _UnavailableBanner extends StatelessWidget {
  const _UnavailableBanner();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: AppColors.warning),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.menuItemUnavailable,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  Text(AppStrings.menuItemUnavailableBody),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllergenBanner extends StatelessWidget {
  const _AllergenBanner({required this.allergens});

  final List<String> allergens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                allergens.join(' · '),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.enabled,
    required this.onChanged,
  });

  final int quantity;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: !enabled || quantity <= 1
                ? null
                : () => onChanged(quantity - 1),
            icon: const Icon(Icons.remove_rounded),
            tooltip: 'Decrease quantity',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              '$quantity',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: !enabled || quantity >= 99
                ? null
                : () => onChanged(quantity + 1),
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Increase quantity',
          ),
        ],
      ),
    );
  }
}

class _VariationGroupSection extends StatelessWidget {
  const _VariationGroupSection({
    required this.group,
    required this.selectedId,
    required this.enabled,
    required this.onSelected,
  });

  final FoodVariationGroup group;
  final String? selectedId;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                group.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              group.required
                  ? AppStrings.requiredChoice
                  : AppStrings.optionalChoice,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          AppStrings.selectOption,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final option in group.options)
              ChoiceChip(
                label: Text(option.labelWithPrice),
                selected: selectedId == option.id,
                onSelected: !enabled
                    ? null
                    : (selected) {
                        if (selected) onSelected(option.id);
                      },
              ),
          ],
        ),
      ],
    );
  }
}

class _AddOnsSection extends StatelessWidget {
  const _AddOnsSection({
    required this.addOns,
    required this.selectedIds,
    required this.enabled,
    required this.onToggle,
  });

  final List<FoodOption> addOns;
  final Set<String> selectedIds;
  final bool enabled;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.addOnsTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final addOn in addOns)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: selectedIds.contains(addOn.id),
            onChanged: !enabled ? null : (_) => onToggle(addOn.id),
            title: Text(addOn.name),
            secondary: Text(
              addOn.formattedDelta.isEmpty ? '' : addOn.formattedDelta,
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
      ],
    );
  }
}
