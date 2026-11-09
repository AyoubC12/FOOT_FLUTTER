import 'package:flutter/material.dart';

abstract final class Breakpoints {
  static const compact = 600.0;
  static const medium = 840.0;
}

extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);

  bool get isCompact => screenSize.width < Breakpoints.compact;

  bool get isMedium =>
      screenSize.width >= Breakpoints.compact &&
      screenSize.width < Breakpoints.medium;

  double gutter() {
    if (isCompact) return 16;
    if (isMedium) return 24;
    return 32;
  }

  int gridCount({int compact = 2, int medium = 3, int expanded = 4}) {
    if (isCompact) return compact;
    if (isMedium) return medium;
    return expanded;
  }
}
