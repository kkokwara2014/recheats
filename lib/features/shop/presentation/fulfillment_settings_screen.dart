import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../application/shop_providers.dart';
import '../domain/shop_fulfillment_settings.dart';

/// Kitchen screen: enable pickup / delivery and set pickup location + fee.
class FulfillmentSettingsScreen extends ConsumerStatefulWidget {
  const FulfillmentSettingsScreen({super.key});

  @override
  ConsumerState<FulfillmentSettingsScreen> createState() =>
      _FulfillmentSettingsScreenState();
}

class _FulfillmentSettingsScreenState
    extends ConsumerState<FulfillmentSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController? _pickupLocation;
  TextEditingController? _deliveryFee;
  bool? _pickupEnabled;
  bool? _deliveryEnabled;
  bool _saving = false;
  String? _boundSettingsKey;

  void _bind(ShopFulfillmentSettings settings) {
    final key =
        '${settings.pickupEnabled}|${settings.deliveryEnabled}|${settings.pickupLocation}|${settings.deliveryFee}';
    if (_boundSettingsKey == key) return;

    _pickupLocation?.dispose();
    _deliveryFee?.dispose();
    _pickupLocation = TextEditingController(text: settings.pickupLocation);
    _deliveryFee = TextEditingController(
      text: settings.deliveryFee.toStringAsFixed(
        settings.deliveryFee == settings.deliveryFee.roundToDouble() ? 0 : 2,
      ),
    );
    _pickupEnabled = settings.pickupEnabled;
    _deliveryEnabled = settings.deliveryEnabled;
    _boundSettingsKey = key;
  }

  @override
  void dispose() {
    _pickupLocation?.dispose();
    _deliveryFee?.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final pickupEnabled = _pickupEnabled ?? true;
    final deliveryEnabled = _deliveryEnabled ?? true;
    if (!pickupEnabled && !deliveryEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.fulfillmentNeedOneMethod)),
      );
      return;
    }

    setState(() => _saving = true);

    final fee = double.tryParse(_deliveryFee!.text.trim()) ?? 0;
    final settings = ShopFulfillmentSettings(
      pickupEnabled: pickupEnabled,
      deliveryEnabled: deliveryEnabled,
      pickupLocation: _pickupLocation!.text.trim(),
      deliveryFee: fee,
    );

    final result = await ref
        .read(shopRepositoryProvider)
        .saveFulfillmentSettings(settings);
    if (!mounted) return;

    result.when(
      success: (_) {
        invalidateShopFulfillmentSettings(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.fulfillmentSettingsSaved)),
        );
        setState(() => _saving = false);
      },
      failure: (error, _) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.userMessage(error))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(shopFulfillmentSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.fulfillmentSettingsTitle)),
      body: settingsAsync.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppErrorView(
          error: error,
          onRetry: () => invalidateShopFulfillmentSettings(ref),
        ),
        data: (settings) {
          _bind(settings);
          final theme = Theme.of(context);

          return ResponsiveLayout(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Text(
                    AppStrings.fulfillmentSettingsSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(AppStrings.fulfillmentOfferPickup),
                    subtitle: const Text(AppStrings.fulfillmentOfferPickupBody),
                    value: _pickupEnabled ?? true,
                    onChanged: (value) =>
                        setState(() => _pickupEnabled = value),
                  ),
                  if (_pickupEnabled ?? true) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _pickupLocation,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: AppStrings.fulfillmentPickupLocationLabel,
                        hintText: AppStrings.fulfillmentPickupLocationHint,
                      ),
                      validator: (value) {
                        if (!(_pickupEnabled ?? true)) return null;
                        if (value == null || value.trim().isEmpty) {
                          return AppStrings.fulfillmentPickupLocationRequired;
                        }
                        return null;
                      },
                    ),
                  ],
                  const Divider(height: AppSpacing.xl),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(AppStrings.fulfillmentOfferDelivery),
                    subtitle:
                        const Text(AppStrings.fulfillmentOfferDeliveryBody),
                    value: _deliveryEnabled ?? true,
                    onChanged: (value) =>
                        setState(() => _deliveryEnabled = value),
                  ),
                  if (_deliveryEnabled ?? true) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _deliveryFee,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: AppStrings.fulfillmentDeliveryFeeLabel,
                        prefixText: '\$ ',
                      ),
                      validator: (value) {
                        if (!(_deliveryEnabled ?? true)) return null;
                        final parsed = double.tryParse(value?.trim() ?? '');
                        if (parsed == null || parsed < 0) {
                          return AppStrings.fulfillmentDeliveryFeeInvalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      AppStrings.fulfillmentDeliveryManualHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(AppStrings.saveChanges),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
