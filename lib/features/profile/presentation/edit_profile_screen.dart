import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/result.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../auth/domain/auth_validators.dart';
import '../application/profile_providers.dart';
import '../data/profile_repository.dart';
import '../domain/customer_profile.dart';
import 'widgets/profile_widgets.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _hydrated = false;
  bool _saving = false;
  bool _photoBusy = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _hydrate(CustomerProfile profile) {
    if (_hydrated) return;
    _firstName.text = profile.firstName;
    _lastName.text = profile.lastName;
    _email.text = profile.email;
    _phone.text = profile.phone ?? '';
    _hydrated = true;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    final result = await ref.read(profileRepositoryProvider).updateDetails(
          firstName: _firstName.text,
          lastName: _lastName.text,
          email: _email.text,
          phone: _phone.text.trim().isEmpty ? null : _phone.text,
        );
    if (!mounted) return;

    result.when(
      success: (_) {
        invalidateCustomerProfile(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.profileSaved)),
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

  Future<void> _changePhoto(CustomerProfile profile) async {
    if (_photoBusy) return;

    final choice = await showModalBottomSheet<_PhotoAction>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text(AppStrings.choosePhoto),
                onTap: () => Navigator.pop(context, _PhotoAction.pick),
              ),
              if (profile.photoUrl != null)
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    AppStrings.removePhoto,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  onTap: () => Navigator.pop(context, _PhotoAction.remove),
                ),
            ],
          ),
        );
      },
    );

    if (choice == null || !mounted) return;

    setState(() => _photoBusy = true);
    final repo = ref.read(profileRepositoryProvider);

    final result = switch (choice) {
      _PhotoAction.remove => await repo.clearPhoto(),
      _PhotoAction.pick => await _pickAndUpload(repo),
    };

    if (!mounted) return;
    setState(() => _photoBusy = false);

    if (result == null) return;

    result.when(
      success: (_) {
        invalidateCustomerProfile(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              choice == _PhotoAction.remove
                  ? AppStrings.photoRemoved
                  : AppStrings.photoUpdated,
            ),
          ),
        );
      },
      failure: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.userMessage(error))),
        );
      },
    );
  }

  Future<Result<CustomerProfile>?> _pickAndUpload(
    ProfileRepository repo,
  ) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return repo.updatePhoto(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(customerProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.editProfile)),
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

          _hydrate(profile);

          return AppLoadingOverlay(
            visible: _photoBusy,
            child: ResponsiveLayout(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Center(
                      child: ProfileAvatar(
                        profile: profile,
                        radius: 48,
                        onEdit: () => _changePhoto(profile),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
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
                        helperText: AppStrings.emailChangeHelper,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      validator: AuthValidators.phoneOptional,
                      onFieldSubmitted: (_) => _save(),
                      decoration: const InputDecoration(
                        labelText: AppStrings.phoneLabel,
                      ),
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
                          : const Text(AppStrings.saveChanges),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _PhotoAction { pick, remove }
