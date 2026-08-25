import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../phone/phone_country.dart';

/// Optional phone field with country-code picker and digit-length limits.
///
/// Form value / [onChanged] emit E.164 (`+13015551234`) or `null` when empty.
class PhoneNumberFormField extends StatefulWidget {
  const PhoneNumberFormField({
    super.key,
    this.initialPhone,
    this.labelText = AppStrings.phoneLabel,
    this.helperText,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.onChanged,
    this.enabled = true,
    this.optional = false,
    this.autofocus = false,
  });

  /// Existing E.164 or national digits to hydrate (edit profile).
  final String? initialPhone;
  final String labelText;
  final String? helperText;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String?>? onChanged;
  final bool enabled;
  final bool optional;
  final bool autofocus;

  @override
  State<PhoneNumberFormField> createState() => PhoneNumberFormFieldState();
}

class PhoneNumberFormFieldState extends State<PhoneNumberFormField> {
  late PhoneCountry _country;
  late final TextEditingController _nationalController;
  final _fieldKey = GlobalKey<FormFieldState<String>>();

  /// Current E.164 value, or `null` when the national field is empty.
  String? get e164Value => PhoneNumberUtils.toE164(
        country: _country,
        nationalRaw: _nationalController.text,
      );

  @override
  void initState() {
    super.initState();
    final parsed = PhoneNumberUtils.parseStored(widget.initialPhone);
    _country = parsed.country;
    _nationalController = TextEditingController(text: parsed.national);
    _nationalController.addListener(_emitChanged);
  }

  @override
  void dispose() {
    _nationalController.removeListener(_emitChanged);
    _nationalController.dispose();
    super.dispose();
  }

  void _emitChanged() {
    widget.onChanged?.call(e164Value);
    _fieldKey.currentState?.didChange(e164Value);
  }

  Future<void> _pickCountry() async {
    if (!widget.enabled) return;
    final selected = await showModalBottomSheet<PhoneCountry>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _CountryPickerSheet(),
    );
    if (selected == null || !mounted) return;

    setState(() {
      _country = selected;
      final digits = PhoneNumberUtils.digitsOnly(_nationalController.text);
      final clipped = digits.length > selected.nationalNumberLength
          ? digits.substring(0, selected.nationalNumberLength)
          : digits;
      if (clipped != _nationalController.text) {
        _nationalController.value = TextEditingValue(
          text: clipped,
          selection: TextSelection.collapsed(offset: clipped.length),
        );
      }
    });
    _emitChanged();
  }

  String? _validate(String? value) {
    final e164 = value?.trim() ?? '';
    if (e164.isEmpty) {
      return widget.optional ? null : 'Enter your phone number';
    }
    final parsed = PhoneNumberUtils.parseStored(e164);
    final expected = parsed.country.nationalNumberLength;
    if (parsed.national.length != expected) {
      return 'Enter a $expected-digit phone number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxLen = _country.nationalNumberLength;

    return FormField<String>(
      key: _fieldKey,
      initialValue: e164Value,
      validator: _validate,
      builder: (field) {
        return TextField(
          controller: _nationalController,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          keyboardType: TextInputType.phone,
          textInputAction: widget.textInputAction,
          autofillHints: const [AutofillHints.telephoneNumberNational],
          onSubmitted: widget.onFieldSubmitted,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(maxLen),
          ],
          decoration: InputDecoration(
            labelText: widget.labelText,
            helperText: widget.helperText ??
                '${_country.flag} ${_country.name} · $maxLen digits',
            errorText: field.errorText,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: UnconstrainedBox(
                child: TextButton(
                  onPressed: widget.enabled ? _pickCountry : null,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    minimumSize: const Size(0, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_country.flag, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 4),
                      Text(
                        _country.dialCodeLabel,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
          ),
        );
      },
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet();

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _query = TextEditingController();
  late List<PhoneCountry> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = PhoneCountry.all;
    _query.addListener(_filter);
  }

  @override
  void dispose() {
    _query.removeListener(_filter);
    _query.dispose();
    super.dispose();
  }

  void _filter() {
    final q = _query.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = PhoneCountry.all;
        return;
      }
      _filtered = PhoneCountry.all
          .where(
            (c) =>
                c.name.toLowerCase().contains(q) ||
                c.dialCode.contains(q) ||
                c.iso2.toLowerCase().contains(q) ||
                '+${c.dialCode}'.contains(q),
          )
          .toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: TextField(
                controller: _query,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search country or code',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final country = _filtered[index];
                  return ListTile(
                    leading:
                        Text(country.flag, style: const TextStyle(fontSize: 22)),
                    title: Text(country.name),
                    subtitle: Text(
                      '${country.dialCodeLabel} · ${country.nationalNumberLength} digits',
                    ),
                    onTap: () => Navigator.pop(context, country),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
