import 'package:flutter/material.dart';

/// Elevation shadows for custom components that need depth beyond Material.
abstract final class AppShadows {
  static const soft = [
    BoxShadow(color: Color(0x1209151A), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const medium = [
    BoxShadow(color: Color(0x1A09151A), blurRadius: 16, offset: Offset(0, 6)),
  ];
  static const large = [
    BoxShadow(color: Color(0x2409151A), blurRadius: 24, offset: Offset(0, 12)),
  ];
}
