import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../application/profile_providers.dart';
import '../domain/address_label.dart';
import '../domain/profile_validators.dart';
import '../domain/saved_address.dart';

class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.existing});

  final SavedAddress? existing;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _line1;
  late final TextEditingController _line2;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _zip;
  late final TextEditingController _instructions;
  late AddressLabel _label;
  late bool _isDefault;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _label = existing?.addressLabel ?? AddressLabel.home;
    _line1 = TextEditingController(text: existing?.line1 ?? '');
    _line2 = TextEditingController(text: existing?.line2 ?? '');
    _city = TextEditingController(text: existing?.city ?? '');
    _state = TextEditingController(text: existing?.state ?? 'MD');
    _zip = TextEditingController(text: existing?.zip ?? '');
    _instructions = TextEditingController(text: existing?.instructions ?? '');
    _isDefault = existing?.isDefault ?? false;
  }

  @override
  void dispose() {
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _state.dispose();
    _zip.dispose();
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    final instructions = _instructions.text.trim();
    final address = SavedAddress(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      label: _label.displayName,
      line1: _line1.text.trim(),
      line2: _line2.text.trim().isEmpty ? null : _line2.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim().toUpperCase(),
      zip: _zip.text.trim(),
      instructions: instructions.isEmpty ? null : instructions,
      isDefault: _isDefault,
    );

    final result =
        await ref.read(profileRepositoryProvider).saveAddress(address);
    if (!mounted) return;

    result.when(
      success: (_) {
        invalidateCustomerProfile(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? AppStrings.addressUpdated : AppStrings.addressSaved,
            ),
          ),
        );
        Navigator.of(context).pop();
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
    final profileAsync = ref.watch(customerProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? AppStrings.editAddress : AppStrings.addAddress,
        ),
      ),
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

          return ResponsiveLayout(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(
                    AppStrings.addressLabel,
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final option in AddressLabel.values)
                        ChoiceChip(
                          label: Text(option.displayName),
                          selected: _label == option,
                          onSelected: (_) => setState(() => _label = option),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _line1,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.streetAddressLine1],
                    validator: ProfileValidators.street,
                    decoration: const InputDecoration(
                      labelText: AppStrings.streetAddress,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _line2,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.streetAddressLine2],
                    decoration: const InputDecoration(
                      labelText: AppStrings.apartmentOptional,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _city,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.addressCity],
                    validator: ProfileValidators.city,
                    decoration: const InputDecoration(
                      labelText: AppStrings.cityLabel,
                      hintText: AppStrings.cityHint,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _state,
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [
                            AutofillHints.addressState,
                          ],
                          validator: ProfileValidators.state,
                          decoration: const InputDecoration(
                            labelText: AppStrings.stateLabel,
                            hintText: AppStrings.stateHint,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: _zip,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.postalCode],
                          validator: ProfileValidators.zip,
                          decoration: const InputDecoration(
                            labelText: AppStrings.zipLabel,
                            hintText: AppStrings.zipHint,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _instructions,
                    maxLines: 3,
                    maxLength: 200,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _save(),
                    decoration: const InputDecoration(
                      labelText: AppStrings.deliveryInstructions,
                      hintText: AppStrings.deliveryInstructionsHint,
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(AppStrings.defaultAddress),
                    subtitle: const Text(AppStrings.defaultAddressHelper),
                    value: _isDefault,
                    onChanged: (value) => setState(() => _isDefault = value),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _isEditing
                                ? AppStrings.saveChanges
                                : AppStrings.saveAddress,
                          ),
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
