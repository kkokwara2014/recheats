import 'package:flutter/material.dart';

import '../constants/app_breakpoints.dart';
import '../constants/app_spacing.dart';

/// Constrains content width and adapts padding by breakpoint.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.child,
    this.maxWidth = AppSpacing.maxContentWidth,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontal = AppBreakpoints.isCompact(width)
            ? AppSpacing.md
            : AppBreakpoints.isMedium(width)
                ? AppSpacing.lg
                : AppSpacing.xl;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: padding ?? EdgeInsets.symmetric(horizontal: horizontal),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Picks a child based on available width.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });

  final WidgetBuilder compact;
  final WidgetBuilder? medium;
  final WidgetBuilder? expanded;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (AppBreakpoints.isExpanded(width) && expanded != null) {
          return expanded!(context);
        }
        if (!AppBreakpoints.isCompact(width) && medium != null) {
          return medium!(context);
        }
        return compact(context);
      },
    );
  }
}
