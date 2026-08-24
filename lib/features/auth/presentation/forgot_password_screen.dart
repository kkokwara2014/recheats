import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/error_handler.dart';
import '../application/auth_providers.dart';
import '../domain/auth_validators.dart';
import 'widgets/auth_form_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _submitting = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    final result =
        await ref.read(authRepositoryProvider).sendPasswordReset(_email.text);
    if (!mounted) return;

    result.when(
      success: (_) {
        setState(() {
          _submitting = false;
          _sent = true;
        });
      },
      failure: (error, _) {
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
      title: AppStrings.forgotPasswordTitle,
      subtitle: _sent
          ? AppStrings.forgotPasswordSentBody
          : AppStrings.forgotPasswordSubtitle,
      child: _sent
          ? FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text(AppStrings.backToSignIn),
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    validator: AuthValidators.email,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: AppStrings.emailLabel,
                    ),
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
                        : const Text(AppStrings.sendResetLink),
                  ),
                ],
              ),
            ),
    );
  }
}
