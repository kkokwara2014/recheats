import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/routing/app_routes.dart';
import '../../onboarding/application/onboarding_providers.dart';
import '../application/auth_navigation.dart';
import '../application/auth_providers.dart';
import '../domain/auth_validators.dart';
import '../domain/register_details.dart';
import 'widgets/auth_form_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);

    final onboardingDone =
        await ref.read(onboardingRepositoryProvider).isCompleted();
    final result = await ref.read(authRepositoryProvider).register(
          RegisterDetails(
            firstName: _firstName.text,
            lastName: _lastName.text,
            email: _email.text,
            password: _password.text,
            phone: _phone.text.trim().isEmpty ? null : _phone.text,
          ),
          onboardingCompleted: onboardingDone,
        );
    if (!mounted) return;

    await result.when(
      success: (_) => navigateAfterAuth(ref, context),
      failure: (error, _) async {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.userMessage(error))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormScaffold(
      title: AppStrings.registerTitle,
      subtitle: AppStrings.registerSubtitle,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _firstName,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.givenName],
              validator: AuthValidators.firstName,
              decoration: const InputDecoration(
                labelText: AppStrings.firstNameLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _lastName,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.familyName],
              validator: AuthValidators.lastName,
              decoration: const InputDecoration(
                labelText: AppStrings.lastNameLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: AuthValidators.email,
              decoration: const InputDecoration(
                labelText: AppStrings.emailLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              validator: AuthValidators.phoneOptional,
              decoration: const InputDecoration(
                labelText: AppStrings.phoneOptionalLabel,
                helperText: AppStrings.phoneOptionalHelper,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AuthPasswordField(
              controller: _password,
              validator: AuthValidators.password,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(AppStrings.createAccount),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed:
                  _submitting ? null : () => context.go(AppRoutes.login),
              child: const Text(AppStrings.haveAccount),
            ),
          ],
        ),
      ),
    );
  }
}
