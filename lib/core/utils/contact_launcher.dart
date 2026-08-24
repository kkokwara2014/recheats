import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_strings.dart';

/// Opens a contact [uri] (`tel:`, `mailto:`, WhatsApp). Shows a snackbar on failure.
Future<void> launchContactUri(BuildContext context, Uri uri) async {
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!context.mounted) return;
  if (!opened) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.supportLaunchFailed)),
    );
  }
}
