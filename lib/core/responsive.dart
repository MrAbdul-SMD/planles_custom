import 'package:flutter/material.dart';

/// Breakpoints for responsive/adaptive layout across mobile, tablet, web, desktop.
class Breakpoints {
  static const double compact = 600;
  static const double medium = 840;
  static const double expanded = 1200;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isCompact => screenWidth < Breakpoints.compact;
  bool get isMedium =>
      screenWidth >= Breakpoints.compact && screenWidth < Breakpoints.medium;
  bool get isExpanded => screenWidth >= Breakpoints.medium;
  bool get isWideDesktop => screenWidth >= Breakpoints.expanded;

  /// Whether to use a navigation rail / side layout instead of bottom bar.
  bool get useSideNav => screenWidth >= Breakpoints.compact;
}

/// Constrains content width for readability on large screens while allowing
/// full-bleed backgrounds.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 1100,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Picks a value based on current window size class.
T responsiveValue<T>(
  BuildContext context, {
  required T compact,
  T? medium,
  T? expanded,
}) {
  if (context.isWideDesktop) return expanded ?? medium ?? compact;
  if (context.isExpanded) return medium ?? compact;
  return compact;
}
