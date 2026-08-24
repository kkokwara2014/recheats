import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_contact.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/utils/contact_launcher.dart';
import '../../../core/widgets/responsive_layout.dart';

/// Simple hub: contact channels + report an order problem.
class CustomerSupportScreen extends StatelessWidget {
  const CustomerSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.customerSupport)),
      body: ResponsiveLayout(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Text(
                AppStrings.supportContactSection,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: const Text(AppStrings.supportCall),
              subtitle: Text(AppContact.phoneDisplay),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => launchContactUri(context, AppContact.callUri),
            ),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text(AppStrings.supportEmail),
              subtitle: Text(AppContact.email),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => launchContactUri(
                context,
                AppContact.emailUri(),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: const Text(AppStrings.supportWhatsApp),
              subtitle: Text(AppContact.phoneDisplay),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => launchContactUri(
                context,
                AppContact.whatsappUri(),
              ),
            ),
            const Divider(height: AppSpacing.lg),
            ListTile(
              leading: const Icon(Icons.report_problem_outlined),
              title: const Text(AppStrings.supportReportSection),
              subtitle: const Text(AppStrings.supportReportSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.profileSupportReport),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pick an issue type, then open email with a short template.
class ReportOrderProblemScreen extends StatelessWidget {
  const ReportOrderProblemScreen({super.key});

  static const _issues = <String>[
    AppStrings.supportProblemMissing,
    AppStrings.supportProblemWrong,
    AppStrings.supportProblemLate,
    AppStrings.supportProblemPayment,
    AppStrings.supportProblemOther,
  ];

  Future<void> _report(BuildContext context, String issue) async {
    final subject = AppStrings.supportReportSubject(issue);
    final body = AppStrings.supportReportBody(issue);
    await launchContactUri(
      context,
      AppContact.emailUri(subject: subject, body: body),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.supportReportSection)),
      body: ResponsiveLayout(
        child: ListView(
          children: [
            for (final issue in _issues)
              ListTile(
                title: Text(issue),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _report(context, issue),
              ),
          ],
        ),
      ),
    );
  }
}
