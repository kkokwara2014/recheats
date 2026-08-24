import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../application/checkout_providers.dart';
import '../../domain/delivery_details.dart';
import '../../../profile/domain/saved_address.dart';

/// Delivery address, apartment/unit, and instructions for checkout.
class DeliveryDetailsForm extends ConsumerStatefulWidget {
  const DeliveryDetailsForm({
    super.key,
    required this.details,
    required this.savedAddresses,
  });

  final DeliveryDetails details;
  final List<SavedAddress> savedAddresses;

  @override
  ConsumerState<DeliveryDetailsForm> createState() =>
      _DeliveryDetailsFormState();
}

class _DeliveryDetailsFormState extends ConsumerState<DeliveryDetailsForm> {
  late final TextEditingController _street;
  late final TextEditingController _apartment;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _zip;
  late final TextEditingController _instructions;
  String? _syncedAddressId;

  @override
  void initState() {
    super.initState();
    _street = TextEditingController(text: widget.details.streetAddress);
    _apartment = TextEditingController(text: widget.details.apartmentUnit);
    _city = TextEditingController(text: widget.details.city);
    _state = TextEditingController(text: widget.details.state);
    _zip = TextEditingController(text: widget.details.zip);
    _instructions = TextEditingController(text: widget.details.instructions);
    _syncedAddressId = widget.details.savedAddressId;
  }

  @override
  void didUpdateWidget(covariant DeliveryDetailsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextId = widget.details.savedAddressId;
    if (nextId != null && nextId != _syncedAddressId) {
      _syncedAddressId = nextId;
      _street.text = widget.details.streetAddress;
      _apartment.text = widget.details.apartmentUnit;
      _city.text = widget.details.city;
      _state.text = widget.details.state;
      _zip.text = widget.details.zip;
      _instructions.text = widget.details.instructions;
    }
  }

  @override
  void dispose() {
    _street.dispose();
    _apartment.dispose();
    _city.dispose();
    _state.dispose();
    _zip.dispose();
    _instructions.dispose();
    super.dispose();
  }

  void _pushField({
    String? streetAddress,
    String? apartmentUnit,
    String? city,
    String? stateCode,
    String? zip,
    String? instructions,
  }) {
    ref.read(checkoutProvider.notifier).updateDelivery(
          streetAddress: streetAddress,
          apartmentUnit: apartmentUnit,
          city: city,
          stateCode: stateCode,
          zip: zip,
          instructions: instructions,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final addresses = widget.savedAddresses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.deliveryDetailsTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (addresses.isNotEmpty) ...[
          Text(
            AppStrings.deliveryUseSavedAddress,
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final address in addresses)
                ChoiceChip(
                  label: Text(address.label),
                  selected: widget.details.savedAddressId == address.id,
                  onSelected: (_) {
                    ref
                        .read(checkoutProvider.notifier)
                        .applySavedAddress(address);
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ] else ...[
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.profileAddressEdit),
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text(AppStrings.addAddress),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        TextFormField(
          controller: _street,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: AppStrings.streetAddress,
          ),
          onChanged: (value) => _pushField(streetAddress: value),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _apartment,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: AppStrings.apartmentUnit,
          ),
          onChanged: (value) => _pushField(apartmentUnit: value),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _city,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: AppStrings.cityLabel,
                ),
                onChanged: (value) => _pushField(city: value),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextFormField(
                controller: _state,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: AppStrings.stateLabel,
                ),
                onChanged: (value) => _pushField(stateCode: value),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextFormField(
                controller: _zip,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: AppStrings.zipLabel,
                ),
                onChanged: (value) => _pushField(zip: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _instructions,
          maxLines: 3,
          maxLength: 200,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: AppStrings.deliveryInstructions,
            hintText: AppStrings.deliveryInstructionsHint,
            alignLabelWithHint: true,
          ),
          onChanged: (value) => _pushField(instructions: value),
        ),
      ],
    );
  }
}
